package main

import (
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
		f := formula.Files[i]
		if f.OSArch != w.osarch {
			t.Errorf("Files[%d].OSArch = %d, want %d", i, f.OSArch, w.osarch)
		}
		if f.SHA256 != w.sha256 {
			t.Errorf("Files[%d].SHA256 = %q, want %q", i, f.SHA256, w.sha256)
		}
		if f.URL != URL+formula.Files[i].URL[len(URL):] {
			t.Errorf("Files[%d].URL does not start with base URL", i)
		}
	}
}
