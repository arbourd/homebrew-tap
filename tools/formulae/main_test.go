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
	plat := map[string]string{"darwin-arm64": "a", "darwin-amd64": "a"}
	ok := Spec{Source: "github", Repo: "o/n", Homepage: "h", Platforms: plat, Desc: "d", Install: []string{"i"}, Test: "t"}
	if err := ok.validate(); err != nil {
		t.Fatalf("validate() error: %v", err)
	}
	// A tool without a macOS Intel build is valid.
	okSingle := Spec{Source: "github", Repo: "o/n", Homepage: "h", Platforms: map[string]string{"darwin-arm64": "a", "linux-amd64": "b", "linux-arm64": "c"}, Desc: "d", Install: []string{"i"}, Test: "t"}
	if err := okSingle.validate(); err != nil {
		t.Fatalf("validate() single arch error: %v", err)
	}
	okGo := Spec{Source: "go", Homepage: "h", ReleaseNotes: "n#{version}", Desc: "d", Install: []string{"i"}, Test: "t"}
	if err := okGo.validate(); err != nil {
		t.Fatalf("validate() error: %v", err)
	}
	for name, bad := range map[string]Spec{
		"no source":      {Repo: "o/n", Homepage: "h", Platforms: plat, Desc: "d", Install: []string{"i"}, Test: "t"},
		"source":         {Source: "gitlab", Repo: "o/n", Desc: "d", Install: []string{"i"}, Test: "t"},
		"go with repo":   {Source: "go", Repo: "o/n", Homepage: "h", ReleaseNotes: "n#{version}", Desc: "d", Install: []string{"i"}, Test: "t"},
		"release_notes":  {Source: "github", Repo: "o/n", Homepage: "h", Platforms: plat, ReleaseNotes: "https://x/notes", Desc: "d", Install: []string{"i"}, Test: "t"},
		"go platforms":   {Source: "go", Platforms: map[string]string{"darwin-arm64": "a"}, Homepage: "h", ReleaseNotes: "n#{version}", Desc: "d", Install: []string{"i"}, Test: "t"},
		"no homepage":    {Source: "github", Repo: "o/n", Platforms: plat, Desc: "d", Install: []string{"i"}, Test: "t"},
		"go no homepage": {Source: "go", ReleaseNotes: "n#{version}", Desc: "d", Install: []string{"i"}, Test: "t"},
		"no platforms":   {Source: "github", Repo: "o/n", Homepage: "h", Desc: "d", Install: []string{"i"}, Test: "t"},
		"bad platform":   {Source: "github", Repo: "o/n", Homepage: "h", Platforms: map[string]string{"plan9-amd64": "a"}, Desc: "d", Install: []string{"i"}, Test: "t"},
		"empty asset":    {Source: "github", Repo: "o/n", Homepage: "h", Platforms: map[string]string{"darwin-arm64": ""}, Desc: "d", Install: []string{"i"}, Test: "t"},
		"asset path":     {Source: "github", Repo: "o/n", Homepage: "h", Platforms: map[string]string{"darwin-arm64": "x/a"}, Desc: "d", Install: []string{"i"}, Test: "t"},
	} {
		if err := bad.validate(); err == nil {
			t.Errorf("validate() %s error = nil", name)
		}
	}
	for field, bad := range map[string]Spec{
		"repo":    {Source: "github", Repo: "n", Homepage: "h", Platforms: plat, Desc: "d", Install: []string{"i"}, Test: "t"},
		"desc":    {Source: "github", Repo: "o/n", Homepage: "h", Platforms: plat, Install: []string{"i"}, Test: "t"},
		"install": {Source: "github", Repo: "o/n", Homepage: "h", Platforms: plat, Desc: "d", Test: "t"},
		"test":    {Source: "github", Repo: "o/n", Homepage: "h", Platforms: plat, Desc: "d", Install: []string{"i"}},
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
	specsYAML = []byte("x:\n  source: github\n  repo: o/n\n  desc: d\n  homepage: h\n  platforms: {darwin-arm64: a, darwin-amd64: a}\n  install: [i]\n  test: t\n  plaftorms: {}\n")
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
		const platforms = "  platforms: {darwin-arm64: a, darwin-amd64: a, linux-amd64: a, linux-arm64: a}\n"
		const base = "  source: github\n  repo: o/n\n  homepage: h\n  desc: d\n  install: [i]\n  test: t\n"
		for name, src := range map[string]string{
			"empty desc":       "a:\n  source: github\n  repo: o/n\n  homepage: h\n  desc: ''\n  install: [i]\n  test: t\n" + platforms,
			"empty test":       "a:\n  source: github\n  repo: o/n\n  homepage: h\n  desc: d\n  install: [i]\n  test: ''\n" + platforms,
			"empty install":    "a:\n  source: github\n  repo: o/n\n  homepage: h\n  desc: d\n  install: ['']\n  test: t\n" + platforms,
			"bad repo":         "a:\n  source: github\n  repo: n\n  homepage: h\n  desc: d\n  install: [i]\n  test: t\n" + platforms,
			"bad name":         "git--get:\n" + base + platforms,
			"no platforms":     "a:\n" + base,
			"empty platforms":  "a:\n" + base + "  platforms: {}\n",
			"empty asset":      "a:\n" + base + "  platforms: {darwin-arm64: ''}\n",
			"asset path":       "a:\n" + base + "  platforms: {darwin-arm64: x/a}\n",
			"go with repo":     "a:\n  source: go\n  repo: o/n\n  homepage: h\n  desc: d\n  install: [i]\n  test: t\n  release_notes: n#{version}\n",
			"no homepage":      "a:\n  source: github\n  repo: o/n\n  desc: d\n  install: [i]\n  test: t\n" + platforms,
			"go no homepage":   "a:\n  source: go\n  desc: d\n  install: [i]\n  test: t\n",
			"notes no version": "a:\n" + base + platforms + "  release_notes: https://x/notes\n",
			"go platforms":     "a:\n  source: go\n  platforms: {darwin-arm64: a}\n  homepage: h\n  release_notes: n#{version}\n  desc: d\n  install: [i]\n  test: t\n",
			"no source":        "a:\n  repo: o/n\n  homepage: h\n  desc: d\n  install: [i]\n  test: t\n" + platforms,
			"empty source":     "a:\n  source: ''\n  repo: o/n\n  homepage: h\n  desc: d\n  install: [i]\n  test: t\n" + platforms,
			"no repo":          "a:\n  source: github\n  homepage: h\n" + platforms + "  desc: d\n  install: [i]\n  test: t\n",
			"unknown platform": "a:\n" + base + "  platforms: {darwin-arm64: a, plan9-amd64: a}\n",
		} {
			if validate(src) == nil {
				t.Errorf("%s: schema accepted invalid entry", name)
			}
		}
		for name, src := range map[string]string{
			"go":              "a:\n  source: go\n  homepage: h\n  release_notes: n#{version}\n  desc: d\n  install: [i]\n  test: t\n",
			"all platforms":   "a:\n" + base + platforms,
			"linux only":      "a:\n" + base + "  platforms: {linux-amd64: a, linux-arm64: a}\n",
			"no darwin intel": "a:\n" + base + "  platforms: {darwin-arm64: a, linux-amd64: a, linux-arm64: a}\n",
			"one platform":    "a:\n" + base + "  platforms: {darwin-arm64: a}\n",
			"macos only":      "a:\n" + base + "  platforms: {darwin-arm64: a, darwin-amd64: a}\n",
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
		if got := props["platforms"].PropertyNames.Enum; !slices.Equal(got, want) {
			t.Errorf("schema platforms enum = %v, want %v", got, want)
		}
	})
}

// constraints returns the lines Homebrew constraints render between version and the first url block.
func constraints(t *testing.T, files []File) string {
	t.Helper()
	got, err := renderFormula(Formula{Files: files})
	if err != nil {
		t.Fatal(err)
	}
	_, rest, _ := strings.Cut(got, "  version \"\"\n")
	header, _, _ := strings.Cut(rest, "  if ")
	return strings.TrimSpace(header)
}

func TestRenderConstraints(t *testing.T) {
	darwinArm, darwinIntel := File{Platform: platforms[0]}, File{Platform: platforms[1]}
	linuxIntel, linuxArm := File{Platform: platforms[2]}, File{Platform: platforms[3]}
	for name, tc := range map[string]struct {
		files []File
		want  string
	}{
		"all four":        {[]File{darwinArm, darwinIntel, linuxIntel, linuxArm}, ""},
		"macos only":      {[]File{darwinArm, darwinIntel}, "depends_on :macos"},
		"linux only":      {[]File{linuxIntel, linuxArm}, "depends_on :linux"},
		"no darwin intel": {[]File{darwinArm, linuxIntel, linuxArm}, "on_macos do\n    depends_on arch: :arm64\n  end"},
		"no darwin arm":   {[]File{darwinIntel, linuxIntel, linuxArm}, "on_macos do\n    depends_on arch: :intel\n  end"},
		"no linux arm":    {[]File{darwinArm, darwinIntel, linuxIntel}, "on_linux do\n    depends_on arch: :intel\n  end"},
		"one macos file":  {[]File{darwinArm}, "depends_on :macos\n  on_macos do\n    depends_on arch: :arm64\n  end"},
		"one linux file":  {[]File{linuxIntel}, "depends_on :linux\n  on_linux do\n    depends_on arch: :intel\n  end"},
		"arm only":        {[]File{darwinArm, linuxArm}, "on_macos do\n    depends_on arch: :arm64\n  end\n  on_linux do\n    depends_on arch: :arm64\n  end"},
	} {
		if got := constraints(t, tc.files); got != tc.want {
			t.Errorf("%s: constraints = %q, want %q", name, got, tc.want)
		}
	}
}
