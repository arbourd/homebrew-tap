package main

import (
	"net/http"
	"net/http/httptest"
	"slices"
	"strings"
	"sync/atomic"
	"testing"
)

// sha returns a valid sha256 made of the hex digit c.
func sha(c string) string { return strings.Repeat(c, 64) }

// supportedGoRelease returns a release with one archive for each supported platform.
func supportedGoRelease() goRelease {
	return goRelease{
		Version: "go1.26.2",
		Files: []goFile{
			{Filename: "go1.26.2.darwin-arm64.tar.gz", SHA256: sha("a"), Kind: "archive"},
			{Filename: "go1.26.2.darwin-amd64.tar.gz", SHA256: sha("b"), Kind: "archive"},
			{Filename: "go1.26.2.linux-amd64.tar.gz", SHA256: sha("c"), Kind: "archive"},
			{Filename: "go1.26.2.linux-arm64.tar.gz", SHA256: sha("d"), Kind: "archive"},
		},
	}
}

func TestBuildGoFormula(t *testing.T) {
	// Unsupported entries are interleaved to check they are filtered out.
	release := supportedGoRelease()
	release.Files = append(release.Files,
		goFile{Filename: "go1.26.2.src.tar.gz", SHA256: sha("f"), Kind: "source"},
		goFile{Filename: "go1.26.2.windows-amd64.zip", SHA256: sha("0"), Kind: "archive"},
	)

	got, err := buildGoFormula("go", specs["go"], release)
	if err != nil {
		t.Fatalf("buildGoFormula() error: %v", err)
	}

	if got.Version != "1.26.2" {
		t.Errorf("Version = %q, want %q", got.Version, "1.26.2")
	}

	want := []File{
		{URL: goDL + "go1.26.2.darwin-arm64.tar.gz", SHA256: sha("a"), Platform: platforms[0]},
		{URL: goDL + "go1.26.2.darwin-amd64.tar.gz", SHA256: sha("b"), Platform: platforms[1]},
		{URL: goDL + "go1.26.2.linux-amd64.tar.gz", SHA256: sha("c"), Platform: platforms[2]},
		{URL: goDL + "go1.26.2.linux-arm64.tar.gz", SHA256: sha("d"), Platform: platforms[3]},
	}
	if !slices.Equal(got.Files, want) {
		t.Errorf("Files = %+v, want %+v", got.Files, want)
	}
}

func TestBuildGoFormulaInvalid(t *testing.T) {
	tests := []struct {
		name   string
		mutate func(*goRelease)
	}{
		{"version", func(r *goRelease) { r.Version = "go1.26.2\nexit" }},
		{"sha256 too short", func(r *goRelease) { r.Files[0].SHA256 = "aaa" }},
		{"sha256 not hex", func(r *goRelease) { r.Files[0].SHA256 = sha("z") }},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			release := supportedGoRelease()
			tt.mutate(&release)
			if _, err := buildGoFormula("go", specs["go"], release); err == nil {
				t.Error("buildGoFormula() error = nil, want validation error")
			}
		})
	}
}

func TestBuildGoFormulaMissingPlatform(t *testing.T) {
	release := supportedGoRelease()
	release.Files = release.Files[:len(release.Files)-1]

	if _, err := buildGoFormula("go", specs["go"], release); err == nil {
		t.Error("buildGoFormula() error = nil, want error for missing platform")
	}
}

func TestBuildGoFormulaNotArchive(t *testing.T) {
	// A file with the right name but another kind (such as source) is not an archive.
	release := supportedGoRelease()
	release.Files[0].Kind = "source"

	if _, err := buildGoFormula("go", specs["go"], release); err == nil {
		t.Error("buildGoFormula() error = nil, want error for non-archive file")
	}
}

func TestFetchReleases(t *testing.T) {
	old := retryDelay
	retryDelay = 0
	t.Cleanup(func() { retryDelay = old })
	const body = `[{"version":"go1.26.2","files":[{"filename":"go1.26.2.linux-amd64.tar.gz","sha256":"ccc","kind":"archive"}]}]`

	tests := []struct {
		name         string
		responses    []int // status per request; the last one repeats
		body         string
		wantRequests int
		wantErr      bool
	}{
		{name: "success", responses: []int{200}, body: body, wantRequests: 1},
		{name: "recovers after server errors", responses: []int{500, 502, 200}, body: body, wantRequests: 3},
		{name: "gives up after max attempts", responses: []int{500}, body: body, wantRequests: maxAttempts, wantErr: true},
		{name: "invalid JSON", responses: []int{200}, body: "<html>", wantRequests: maxAttempts, wantErr: true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var requests atomic.Int32
			srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				status := tt.responses[min(int(requests.Add(1))-1, len(tt.responses)-1)]
				w.WriteHeader(status)
				if status == http.StatusOK {
					_, _ = w.Write([]byte(tt.body))
				}
			}))
			defer srv.Close()

			got, err := fetchGoReleases(srv.URL)
			if (err != nil) != tt.wantErr {
				t.Fatalf("fetchGoReleases() error = %v, wantErr %v", err, tt.wantErr)
			}
			if got := int(requests.Load()); got != tt.wantRequests {
				t.Errorf("requests = %d, want %d", got, tt.wantRequests)
			}
			if !tt.wantErr && (len(got) != 1 || got[0].Version != "go1.26.2") {
				t.Errorf("fetchGoReleases() = %+v, want one release go1.26.2", got)
			}
		})
	}
}
