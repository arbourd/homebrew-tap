package main

import (
	"flag"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"slices"
	"sync/atomic"
	"testing"
)

var update = flag.Bool("update", false, "update golden files")

// supportedRelease returns a release with one archive for each supported platform.
func supportedRelease() Release {
	return Release{
		Version: "go1.26.2",
		Files: []ReleaseFile{
			{Filename: "go1.26.2.darwin-arm64.tar.gz", OS: "darwin", Arch: "arm64", SHA256: "aaa", Kind: "archive"},
			{Filename: "go1.26.2.darwin-amd64.tar.gz", OS: "darwin", Arch: "amd64", SHA256: "bbb", Kind: "archive"},
			{Filename: "go1.26.2.linux-amd64.tar.gz", OS: "linux", Arch: "amd64", SHA256: "ccc", Kind: "archive"},
			{Filename: "go1.26.2.linux-arm64.tar.gz", OS: "linux", Arch: "arm64", SHA256: "ddd", Kind: "archive"},
			{Filename: "go1.26.2.linux-armv6l.tar.gz", OS: "linux", Arch: "armv6l", SHA256: "eee", Kind: "archive"},
		},
	}
}

func TestRenderFormula(t *testing.T) {
	formula, err := buildFormula(supportedRelease())
	if err != nil {
		t.Fatalf("buildFormula() error: %v", err)
	}

	got, err := renderFormula(formula)
	if err != nil {
		t.Fatalf("renderFormula() error: %v", err)
	}

	golden := filepath.Join("testdata", "go.rb.golden")
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
}

func TestBuildFormula(t *testing.T) {
	// Unsupported entries are interleaved to check they are filtered out.
	release := supportedRelease()
	release.Files = append(release.Files,
		ReleaseFile{Filename: "go1.26.2.src.tar.gz", SHA256: "fff", Kind: "source"},
		ReleaseFile{Filename: "go1.26.2.windows-amd64.zip", OS: "windows", Arch: "amd64", SHA256: "ggg", Kind: "archive"},
	)

	got, err := buildFormula(release)
	if err != nil {
		t.Fatalf("buildFormula() error: %v", err)
	}

	if got.Version != "1.26.2" {
		t.Errorf("Version = %q, want %q", got.Version, "1.26.2")
	}

	want := []File{
		{URL: baseURL + "go1.26.2.darwin-arm64.tar.gz", SHA256: "aaa", OSArch: DarwinArm64},
		{URL: baseURL + "go1.26.2.darwin-amd64.tar.gz", SHA256: "bbb", OSArch: DarwinAmd64},
		{URL: baseURL + "go1.26.2.linux-amd64.tar.gz", SHA256: "ccc", OSArch: LinuxAmd64},
		{URL: baseURL + "go1.26.2.linux-arm64.tar.gz", SHA256: "ddd", OSArch: LinuxArm64},
		{URL: baseURL + "go1.26.2.linux-armv6l.tar.gz", SHA256: "eee", OSArch: LinuxArm},
	}
	if !slices.Equal(got.Files, want) {
		t.Errorf("Files = %+v, want %+v", got.Files, want)
	}
}

func TestBuildFormulaMissingPlatform(t *testing.T) {
	release := supportedRelease()
	release.Files = release.Files[:len(release.Files)-1]

	if _, err := buildFormula(release); err == nil {
		t.Error("buildFormula() error = nil, want error for missing platform")
	}
}

func TestBuildFormulaDuplicatePlatform(t *testing.T) {
	// Five archives, but linux-armv6l is replaced by a second linux-amd64.
	release := supportedRelease()
	release.Files[4] = release.Files[2]

	if _, err := buildFormula(release); err == nil {
		t.Error("buildFormula() error = nil, want error for duplicate and missing platform")
	}
}

func TestFetchReleases(t *testing.T) {
	old := retryDelay
	retryDelay = 0
	t.Cleanup(func() { retryDelay = old })
	const body = `[{"version":"go1.26.2","files":[{"filename":"go1.26.2.linux-amd64.tar.gz","os":"linux","arch":"amd64","sha256":"ccc","kind":"archive"}]}]`

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
					w.Write([]byte(tt.body))
				}
			}))
			defer srv.Close()

			got, err := fetchReleases(srv.URL)
			if (err != nil) != tt.wantErr {
				t.Fatalf("fetchReleases() error = %v, wantErr %v", err, tt.wantErr)
			}
			if got := int(requests.Load()); got != tt.wantRequests {
				t.Errorf("requests = %d, want %d", got, tt.wantRequests)
			}
			if !tt.wantErr && (len(got) != 1 || got[0].Version != "go1.26.2") {
				t.Errorf("fetchReleases() = %+v, want one release go1.26.2", got)
			}
		})
	}
}
