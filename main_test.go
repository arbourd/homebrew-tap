package main

import (
	"fmt"
	"strings"
	"testing"
)

func TestProcessVersion(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"go1.26", "1.26"},
		{"go1.26.2", "1.26.2"},
		{"1.26", "1.26"},
	}
	for _, tt := range tests {
		got := processVersion(tt.input)
		if got != tt.want {
			t.Errorf("processVersion(%q) = %q, want %q", tt.input, got, tt.want)
		}
	}
}

func TestRenderFormula(t *testing.T) {
	formula := Formula{
		Version: "1.26.2",
		Files: []File{
			{URL: "https://go.dev/dl/go1.26.2.darwin-arm64.tar.gz", SHA256: "aaa", OSArch: DarwinArm64},
			{URL: "https://go.dev/dl/go1.26.2.linux-amd64.tar.gz", SHA256: "bbb", OSArch: LinuxAmd64},
		},
	}

	got, err := renderFormula(formula)
	if err != nil {
		t.Fatalf("renderFormula() error: %v", err)
	}

	checks := []string{
		`version "1.26.2"`,
		`OS.mac? && Hardware::CPU.arm?`,
		`url "https://go.dev/dl/go1.26.2.darwin-arm64.tar.gz"`,
		`sha256 "aaa"`,
		`OS.linux? && Hardware::CPU.intel?`,
		`url "https://go.dev/dl/go1.26.2.linux-amd64.tar.gz"`,
		`sha256 "bbb"`,
	}
	for _, want := range checks {
		if !strings.Contains(got, want) {
			t.Errorf("renderFormula() missing %q", want)
		}
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
			if !strings.HasPrefix(f.URL, URL) {
				t.Errorf("URL %q does not start with base URL %q", f.URL, URL)
			}
		})
	}
}
