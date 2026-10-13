package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

var update = flag.Bool("update", false, "update golden files")

func TestRenderFormula(t *testing.T) {
	formula := buildFormula(Release{
		Version: "go1.26.2",
		Files: []ReleaseFile{
			{Filename: "go1.26.2.darwin-arm64.tar.gz", OS: "darwin", Arch: "arm64", SHA256: "aaa", Kind: "archive"},
			{Filename: "go1.26.2.darwin-amd64.tar.gz", OS: "darwin", Arch: "amd64", SHA256: "bbb", Kind: "archive"},
			{Filename: "go1.26.2.linux-amd64.tar.gz", OS: "linux", Arch: "amd64", SHA256: "ccc", Kind: "archive"},
			{Filename: "go1.26.2.linux-arm64.tar.gz", OS: "linux", Arch: "arm64", SHA256: "ddd", Kind: "archive"},
			{Filename: "go1.26.2.linux-armv6l.tar.gz", OS: "linux", Arch: "armv6l", SHA256: "eee", Kind: "archive"},
		},
	})

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
	release := Release{
		Version: "go1.26.2",
		Files: []ReleaseFile{
			{Filename: "go1.26.2.darwin-arm64.tar.gz", OS: "darwin", Arch: "arm64", SHA256: "aaa", Kind: "archive"},
			{Filename: "go1.26.2.darwin-amd64.tar.gz", OS: "darwin", Arch: "amd64", SHA256: "bbb", Kind: "archive"},
			{Filename: "go1.26.2.linux-amd64.tar.gz", OS: "linux", Arch: "amd64", SHA256: "ccc", Kind: "archive"},
			{Filename: "go1.26.2.linux-arm64.tar.gz", OS: "linux", Arch: "arm64", SHA256: "ddd", Kind: "archive"},
			{Filename: "go1.26.2.linux-armv6l.tar.gz", OS: "linux", Arch: "armv6l", SHA256: "eee", Kind: "archive"},
			{Filename: "go1.26.2.src.tar.gz", OS: "", Arch: "", SHA256: "fff", Kind: "source"},
			{Filename: "go1.26.2.windows-amd64.zip", OS: "windows", Arch: "amd64", SHA256: "ggg", Kind: "archive"},
		},
	}

	formula := buildFormula(release)

	if formula.Version != "1.26.2" {
		t.Errorf("Version = %q, want %q", formula.Version, "1.26.2")
	}

	if len(formula.Files) != 5 {
		t.Errorf("len(Files) = %d, want 5", len(formula.Files))
	}

	want := []struct {
		osarch OSArch
		sha256 string
	}{
		{DarwinArm64, "aaa"},
		{DarwinAmd64, "bbb"},
		{LinuxAmd64, "ccc"},
		{LinuxArm64, "ddd"},
		{LinuxArm, "eee"},
	}
	for i, w := range want {
		t.Run(fmt.Sprintf("file[%d]", i), func(t *testing.T) {
			f := formula.Files[i]
			if f.OSArch != w.osarch {
				t.Errorf("OSArch = %d, want %d", f.OSArch, w.osarch)
			}
			if f.SHA256 != w.sha256 {
				t.Errorf("SHA256 = %q, want %q", f.SHA256, w.sha256)
			}
			if !strings.HasPrefix(f.URL, baseURL) {
				t.Errorf("URL %q does not start with base URL %q", f.URL, baseURL)
			}
		})
	}
}
