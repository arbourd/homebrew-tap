package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"os"
	"path/filepath"
	"reflect"
	"slices"
	"strings"
	"testing"

	"github.com/santhosh-tekuri/jsonschema/v6"
	"gopkg.in/yaml.v3"
)

var update = flag.Bool("update", false, "update golden files")

func TestRenderFormula(t *testing.T) {
	for name, spec := range specs {
		t.Run(name, func(t *testing.T) {
			var formula Formula
			var err error
			if spec.Source == "go" {
				formula, err = buildGoFormula(name, spec, supportedGoRelease())
			} else {
				formula, err = buildFormula(name, spec, release(name))
			}
			if err != nil {
				t.Fatalf("build error: %v", err)
			}
			got, err := renderFormula(formula)
			if err != nil {
				t.Fatalf("renderFormula() error: %v", err)
			}

			golden := filepath.Join("testdata", name+".rb.golden")
			if *update {
				if err := os.MkdirAll("testdata", 0o755); err != nil {
					t.Fatal(err)
				}
				if err := os.WriteFile(golden, []byte(got), 0o644); err != nil {
					t.Fatal(err)
				}
			}

			want, err := os.ReadFile(golden)
			if err != nil {
				t.Fatalf("cannot read golden file (run with -update to create): %v", err)
			}
			if got != string(want) {
				t.Errorf("renderFormula() does not match %s (run with -update to regenerate)\n--- got ---\n%s", golden, got)
			}
		})
	}
}

func TestSpecValidate(t *testing.T) {
	ok := Spec{Repo: "o/n", Desc: "d", Install: []string{"i"}, Test: "t"}
	if err := ok.validate(); err != nil {
		t.Fatalf("validate() error: %v", err)
	}
	okGo := Spec{Source: "go", Homepage: "h", ReleaseNotes: "n#{version}", Desc: "d", Install: []string{"i"}, Test: "t"}
	if err := okGo.validate(); err != nil {
		t.Fatalf("validate() error: %v", err)
	}
	for name, bad := range map[string]Spec{
		"source":         {Source: "gitlab", Repo: "o/n", Desc: "d", Install: []string{"i"}, Test: "t"},
		"go with repo":   {Source: "go", Repo: "o/n", Homepage: "h", ReleaseNotes: "n#{version}", Desc: "d", Install: []string{"i"}, Test: "t"},
		"release_notes":  {Repo: "o/n", ReleaseNotes: "https://x/notes", Desc: "d", Install: []string{"i"}, Test: "t"},
		"go mac_only":    {Source: "go", MacOnly: true, Homepage: "h", ReleaseNotes: "n#{version}", Desc: "d", Install: []string{"i"}, Test: "t"},
		"go no homepage": {Source: "go", ReleaseNotes: "n#{version}", Desc: "d", Install: []string{"i"}, Test: "t"},
	} {
		if err := bad.validate(); err == nil {
			t.Errorf("validate() %s error = nil", name)
		}
	}
	for field, bad := range map[string]Spec{
		"repo":    {Repo: "n", Desc: "d", Install: []string{"i"}, Test: "t"},
		"desc":    {Repo: "o/n", Install: []string{"i"}, Test: "t"},
		"install": {Repo: "o/n", Desc: "d", Test: "t"},
		"test":    {Repo: "o/n", Desc: "d", Install: []string{"i"}},
	} {
		if err := bad.validate(); err == nil || !strings.Contains(err.Error(), field) {
			t.Errorf("validate() without %s error = %v", field, err)
		}
	}
}

func TestLoadSpecsUnknownKey(t *testing.T) {
	orig := specsYAML
	defer func() {
		specsYAML = orig
		if recover() == nil {
			t.Error("loadSpecs() with unknown key did not panic")
		}
	}()
	specsYAML = []byte("x:\n  repo: o/n\n  mac-only: true\n")
	loadSpecs()
}

func TestSchema(t *testing.T) {
	b, err := os.ReadFile("formulae.schema.json")
	if err != nil {
		t.Fatal(err)
	}
	doc, err := jsonschema.UnmarshalJSON(bytes.NewReader(b))
	if err != nil {
		t.Fatal(err)
	}
	c := jsonschema.NewCompiler()
	if err := c.AddResource("formulae.schema.json", doc); err != nil {
		t.Fatal(err)
	}
	sch, err := c.Compile("formulae.schema.json")
	if err != nil {
		t.Fatalf("compile schema: %v", err)
	}
	validate := func(src string) error {
		var v any
		if err := yaml.Unmarshal([]byte(src), &v); err != nil {
			t.Fatal(err)
		}
		return sch.Validate(v)
	}

	t.Run("formulae.yaml", func(t *testing.T) {
		if err := validate(string(specsYAML)); err != nil {
			t.Errorf("does not match schema: %v", err)
		}
	})

	// The schema must reject what Spec.validate and class() reject, or editors miss errors that panic at load.
	t.Run("rejects", func(t *testing.T) {
		const urls = "  urls: {darwin-arm64: a, darwin-amd64: a, linux-amd64: a, linux-arm64: a}\n"
		const base = "  repo: o/n\n  desc: d\n  install: [i]\n  test: t\n"
		for name, src := range map[string]string{
			"empty desc":       "a:\n  repo: o/n\n  desc: ''\n  install: [i]\n  test: t\n",
			"empty test":       "a:\n  repo: o/n\n  desc: d\n  install: [i]\n  test: ''\n",
			"empty install":    "a:\n  repo: o/n\n  desc: d\n  install: ['']\n  test: t\n",
			"bad repo":         "a:\n  repo: n\n  desc: d\n  install: [i]\n  test: t\n",
			"bad name":         "git--get:\n" + base,
			"empty urls":       "a:\n" + base + "  urls: {}\n",
			"empty url":        "a:\n" + base + "  urls: {darwin-arm64: '', darwin-amd64: a, linux-amd64: a, linux-arm64: a}\n",
			"missing linux":    "a:\n" + base + "  urls: {darwin-arm64: a, darwin-amd64: a}\n",
			"go with repo":     "a:\n" + base + "  source: go\n  homepage: h\n  release_notes: n#{version}\n",
			"go no homepage":   "a:\n  source: go\n  desc: d\n  install: [i]\n  test: t\n",
			"notes no version": "a:\n" + base + "  release_notes: https://x/notes\n",
			"go mac_only":      "a:\n  source: go\n  mac_only: true\n  homepage: h\n  release_notes: n#{version}\n  desc: d\n  install: [i]\n  test: t\n",
			"no repo":          "a:\n  desc: d\n  install: [i]\n  test: t\n",
			"unknown platform": "a:\n" + base + "  urls: {darwin-arm64: a, darwin-amd64: a, linux-amd64: a, linux-arm64: a, plan9-amd64: a}\n",
		} {
			if validate(src) == nil {
				t.Errorf("%s: schema accepted invalid entry", name)
			}
		}
		for name, src := range map[string]string{
			"go":                     "a:\n  source: go\n  homepage: h\n  release_notes: n#{version}\n  desc: d\n  install: [i]\n  test: t\n",
			"urls":                   "a:\n" + base + urls,
			"mac_only without linux": "a:\n" + base + "  mac_only: true\n  urls: {darwin-arm64: a, darwin-amd64: a}\n",
		} {
			if err := validate(src); err != nil {
				t.Errorf("%s: schema rejected valid entry: %v", name, err)
			}
		}
	})

	var s struct {
		AdditionalProperties struct {
			Properties map[string]struct {
				PropertyNames struct {
					Enum []string `json:"enum"`
				} `json:"propertyNames"`
			} `json:"properties"`
		} `json:"additionalProperties"`
	}
	if err := json.Unmarshal(b, &s); err != nil {
		t.Fatal(err)
	}
	props := s.AdditionalProperties.Properties

	// Spec fields and schema properties must match in both directions.
	t.Run("fields", func(t *testing.T) {
		seen := map[string]bool{}
		rt := reflect.TypeOf(Spec{})
		for i := range rt.NumField() {
			key, _, _ := strings.Cut(rt.Field(i).Tag.Get("yaml"), ",")
			seen[key] = true
			if _, ok := props[key]; !ok {
				t.Errorf("Spec field %q is missing from the schema", key)
			}
		}
		for key := range props {
			if !seen[key] {
				t.Errorf("schema property %q is not a Spec field", key)
			}
		}
	})

	t.Run("platforms", func(t *testing.T) {
		var want []string
		for _, p := range platforms {
			want = append(want, p.Suffix)
		}
		if got := props["urls"].PropertyNames.Enum; !slices.Equal(got, want) {
			t.Errorf("schema urls enum = %v, want %v", got, want)
		}
	})
}
