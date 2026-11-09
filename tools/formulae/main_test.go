package main

import (
	"flag"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

var update = flag.Bool("update", false, "update golden files")

// release returns a release with one digested asset for each platform.
func release(name string) Release {
	r := Release{Tag: "v1.2.3"}
	for i, p := range platforms {
		file := fmt.Sprintf("%s-v1.2.3-%s.tar.gz", name, p.Suffix)
		r.Assets = append(r.Assets, Asset{
			Name:   file,
			Digest: fmt.Sprintf("sha256:%064d", i+1),
		})
	}
	// Assets we don't use must be ignored.
	r.Assets = append(r.Assets, Asset{Name: "checksums.txt"})
	return r
}

func TestRenderFormula(t *testing.T) {
	for name, spec := range specs {
		t.Run(name, func(t *testing.T) {
			formula, err := buildFormula(name, spec, release(name))
			if err != nil {
				t.Fatalf("buildFormula() error: %v", err)
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

func TestBuildFormulaErrors(t *testing.T) {
	r := release("git-open")
	r.Assets[0].Digest = ""                          // darwin-arm64: no digest
	r.Assets = append(r.Assets[:2], r.Assets[3:]...) // linux-amd64: missing

	_, err := buildFormula("git-open", specs["git-open"], r)
	if err == nil {
		t.Fatal("buildFormula() error = nil, want error")
	}
	for _, want := range []string{"darwin-arm64.tar.gz has no sha256 digest", "linux-amd64.tar.gz is missing"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("error %q does not contain %q", err, want)
		}
	}
}

func TestFetchRelease(t *testing.T) {
	old := retryDelay
	retryDelay = 0
	t.Cleanup(func() { retryDelay = old })

	t.Setenv("GITHUB_TOKEN", "tok")
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		if req.Header.Get("Authorization") != "Bearer tok" {
			http.Error(w, "no auth", http.StatusUnauthorized)
			return
		}
		fmt.Fprint(w, `{"tag_name":"v1.2.3","assets":[{"name":"a","digest":"sha256:abc"}]}`)
	}))
	defer srv.Close()

	got, err := fetchRelease(srv.URL)
	if err != nil {
		t.Fatalf("fetchRelease() error: %v", err)
	}
	if got.Tag != "v1.2.3" || len(got.Assets) != 1 || got.Assets[0].Digest != "sha256:abc" {
		t.Errorf("fetchRelease() = %+v", got)
	}

	t.Setenv("GITHUB_TOKEN", "")
	if _, err := fetchRelease(srv.URL); err == nil {
		t.Error("fetchRelease() without token error = nil, want error")
	}
}

func TestFetchReleaseRetries(t *testing.T) {
	old := retryDelay
	retryDelay = 0
	t.Cleanup(func() { retryDelay = old })

	requests := 0
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		requests++
		if requests < maxAttempts {
			http.Error(w, "boom", http.StatusBadGateway)
			return
		}
		fmt.Fprint(w, `{"tag_name":"v1.2.3"}`)
	}))
	defer srv.Close()

	got, err := fetchRelease(srv.URL)
	if err != nil || got.Tag != "v1.2.3" || requests != maxAttempts {
		t.Errorf("fetchRelease() = %+v, %v after %d requests", got, err, requests)
	}
}

func TestSpecValidate(t *testing.T) {
	ok := Spec{Repo: "o/n", Desc: "d", Install: []string{"i"}, Test: "t"}
	if err := ok.validate(); err != nil {
		t.Fatalf("validate() error: %v", err)
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
