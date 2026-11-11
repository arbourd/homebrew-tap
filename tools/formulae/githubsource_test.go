package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// release returns a release with one digested asset for each platform.
func release(name string) Release {
	r := Release{Tag: "v1.2.3"}
	for i, p := range platforms {
		file, ok := specs[name].Platforms[p.Suffix]
		if !ok {
			continue
		}
		r.Assets = append(r.Assets, Asset{
			Name:   strings.ReplaceAll(file, "#{version}", "1.2.3"),
			Digest: fmt.Sprintf("sha256:%064d", i+1),
		})
	}
	// Assets we don't use must be ignored.
	r.Assets = append(r.Assets, Asset{Name: "checksums.txt"})
	return r
}

func TestBuildFormulaErrors(t *testing.T) {
	r := release("git-open")
	r.Assets[0].Digest = ""                          // darwin-arm64: no digest
	r.Assets = append(r.Assets[:2], r.Assets[3:]...) // linux-amd64: missing

	_, err := buildFormula("git-open", specs["git-open"], r)
	if err == nil {
		t.Fatal("buildFormula() error = nil, want error")
	}
	for _, want := range []string{"darwin-arm64.tar.gz has no valid sha256 digest", "linux-amd64.tar.gz is missing"} {
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

func TestBuildFormulaInvalid(t *testing.T) {
	tests := map[string]func(*Release){
		"tag":              func(r *Release) { r.Tag = "v1.2.3\"\nevil" },
		"tag no v":         func(r *Release) { r.Tag = "1.2.3" },
		"tag prerelease":   func(r *Release) { r.Tag = "v1.2.3-rc1" },
		"digest empty":     func(r *Release) { r.Assets[0].Digest = "sha256:" },
		"digest not hex":   func(r *Release) { r.Assets[0].Digest = "sha256:" + strings.Repeat("z", 64) },
		"digest no prefix": func(r *Release) { r.Assets[0].Digest = strings.Repeat("a", 64) },
		"digest too short": func(r *Release) { r.Assets[0].Digest = "sha256:abc" },
	}
	for name, mutate := range tests {
		t.Run(name, func(t *testing.T) {
			r := release("git-open")
			mutate(&r)
			if _, err := buildFormula("git-open", specs["git-open"], r); err == nil {
				t.Error("buildFormula() error = nil, want validation error")
			}
		})
	}
}

// A release without a macOS Intel build keeps its Intel Mac out of the formula and constrains macOS to arm64.
func TestBuildFormulaNoDarwinIntel(t *testing.T) {
	spec := Spec{Source: "github", Repo: "o/tool", Homepage: "h", Desc: "d", Install: []string{"i"}, Test: "t", Platforms: map[string]string{
		"darwin-arm64": "tool-macos-arm64",
		"linux-amd64":  "tool-linux-amd64",
		"linux-arm64":  "tool-linux-arm64",
	}}
	r := Release{Tag: "v1.2.3"}
	for i, name := range []string{"tool-macos-arm64", "tool-linux-amd64", "tool-linux-arm64", "tool-macos-x86"} {
		r.Assets = append(r.Assets, Asset{Name: name, Digest: fmt.Sprintf("sha256:%064d", i+1)})
	}

	f, err := buildFormula("tool", spec, r)
	if err != nil {
		t.Fatalf("buildFormula() error: %v", err)
	}
	got, err := renderFormula(f)
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{
		"on_macos do\n    depends_on arch: :arm64\n  end",
		"if OS.mac? && Hardware::CPU.arm?\n    url \"https://github.com/o/tool/releases/download/v#{version}/tool-macos-arm64\"",
		"if OS.linux? && Hardware::CPU.intel?",
		"if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?",
	} {
		if !strings.Contains(got, want) {
			t.Errorf("formula is missing %q:\n%s", want, got)
		}
	}
	for _, unwanted := range []string{"OS.mac? && Hardware::CPU.intel?", "tool-macos-x86", "depends_on :macos", "depends_on :linux", "on_linux"} {
		if strings.Contains(got, unwanted) {
			t.Errorf("formula has unwanted %q:\n%s", unwanted, got)
		}
	}
}
