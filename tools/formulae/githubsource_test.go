package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"path"
	"strings"
	"testing"
)

// release returns a release with one digested asset for each platform.
func release(name string) Release {
	r := Release{Tag: "v1.2.3"}
	for i, p := range platforms {
		file := fmt.Sprintf("%s-v1.2.3-%s.tar.gz", name, p.Suffix)
		if u := specs[name].URLs; u != nil {
			file = path.Base(strings.ReplaceAll(u[p.Suffix], "#{version}", "1.2.3"))
		}
		r.Assets = append(r.Assets, Asset{
			Name:   file,
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
		_, _ = fmt.Fprint(w, `{"tag_name":"v1.2.3","assets":[{"name":"a","digest":"sha256:abc"}]}`)
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
		_, _ = fmt.Fprint(w, `{"tag_name":"v1.2.3"}`)
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
		"tag prerelease":   func(r *Release) { r.Tag = "v1.2.3-rc1" },
		"digest empty":     func(r *Release) { r.Assets[0].Digest = "sha256:" },
		"digest not hex":   func(r *Release) { r.Assets[0].Digest = "sha256:" + strings.Repeat("z", 64) },
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
