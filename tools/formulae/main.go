// Command formulae prints a formula for one project, built from the latest GitHub release.
package main

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"slices"
	"strings"
	"text/template"
	"time"

	"gopkg.in/yaml.v3"
)

// Spec describes a formula. Releases follow GoReleaser's `<name>-v<ver>-<os>-<arch>.tar.gz` layout.
type Spec struct {
	Repo      string   `yaml:"repo"`
	Desc      string   `yaml:"desc"`
	MacOnly   bool     `yaml:"mac_only"`
	Conflicts []string `yaml:"conflicts"`
	Install   []string `yaml:"install"`
	Test      string   `yaml:"test"`
}

type Asset struct {
	Name   string `json:"name"`
	Digest string `json:"digest"`
}

type Release struct {
	Tag    string  `json:"tag_name"`
	Assets []Asset `json:"assets"`
}

// Platform is one release target. Suffix is the asset name's `<os>-<arch>` part.
type Platform struct {
	Suffix    string
	Condition string // Homebrew condition that selects the platform
	Mac       bool
}

// platforms is ordered so the macOS entries come first in the formula.
var platforms = []Platform{
	{"darwin-arm64", "OS.mac? && Hardware::CPU.arm?", true},
	{"darwin-amd64", "OS.mac? && Hardware::CPU.intel?", true},
	{"linux-amd64", "OS.linux? && Hardware::CPU.intel?", false},
	{"linux-arm64", "OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?", false},
}

type File struct {
	SHA256   string
	Platform Platform
}

type Formula struct {
	Spec
	Name    string
	Class   string
	Version string
	Files   []File
}

const (
	requestTimeout = 10 * time.Second
	maxAttempts    = 3
)

// retryDelay is the base wait between attempts; it grows linearly. A var so tests can zero it.
var retryDelay = time.Second

//go:embed formulae.yaml
var specsYAML []byte

var specs = loadSpecs()

func loadSpecs() map[string]Spec {
	var m map[string]Spec
	dec := yaml.NewDecoder(bytes.NewReader(specsYAML))
	dec.KnownFields(true)
	if err := dec.Decode(&m); err != nil {
		panic(fmt.Sprintf("cannot parse formulae.yaml: %v", err))
	}
	for name, spec := range m {
		if err := spec.validate(); err != nil {
			panic(fmt.Sprintf("formulae.yaml: %s: %v", name, err))
		}
	}
	return m
}

func (s Spec) validate() error {
	switch {
	case strings.Count(s.Repo, "/") != 1 || strings.HasPrefix(s.Repo, "/") || strings.HasSuffix(s.Repo, "/"):
		return fmt.Errorf("repo %q must be owner/name", s.Repo)
	case s.Desc == "":
		return fmt.Errorf("desc is required")
	case len(s.Install) == 0:
		return fmt.Errorf("install is required")
	case s.Test == "":
		return fmt.Errorf("test is required")
	}
	return nil
}

func main() {
	if len(os.Args) == 2 && os.Args[1] == "--list" {
		if err := json.NewEncoder(os.Stdout).Encode(names()); err != nil {
			log.Fatal(err)
		}
		return
	}
	if len(os.Args) != 2 {
		log.Fatalf("usage: formulae <name> | --list; names: %s", strings.Join(names(), ", "))
	}
	name := os.Args[1]
	spec, ok := specs[name]
	if !ok {
		log.Fatalf("unknown formula %q; names: %s", name, strings.Join(names(), ", "))
	}

	r, err := fetchRelease("https://api.github.com/repos/" + spec.Repo + "/releases/latest")
	if err != nil {
		log.Fatalf("cannot get %s release: %v", spec.Repo, err)
	}
	formula, err := buildFormula(name, spec, r)
	if err != nil {
		log.Fatalf("cannot build formula: %v", err)
	}
	s, err := renderFormula(formula)
	if err != nil {
		log.Fatalf("cannot render formula: %v", err)
	}
	fmt.Print(s)
}

func names() []string {
	n := make([]string, 0, len(specs))
	for k := range specs {
		n = append(n, k)
	}
	slices.Sort(n)
	return n
}

// fetchRelease retrieves the latest release from url, trying up to maxAttempts times.
func fetchRelease(url string) (Release, error) {
	client := &http.Client{Timeout: requestTimeout}

	var err error
	for attempt := 1; attempt <= maxAttempts; attempt++ {
		var r Release
		if r, err = fetchReleaseOnce(client, url); err == nil {
			return r, nil
		}
		log.Printf("attempt %d/%d failed: %v", attempt, maxAttempts, err)
		if attempt < maxAttempts {
			time.Sleep(time.Duration(attempt) * retryDelay)
		}
	}
	return Release{}, err
}

func fetchReleaseOnce(client *http.Client, url string) (Release, error) {
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return Release{}, err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	if token := os.Getenv("GITHUB_TOKEN"); token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	res, err := client.Do(req)
	if err != nil {
		return Release{}, err
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		return Release{}, fmt.Errorf("unexpected status: %s", res.Status)
	}

	var r Release
	if err := json.NewDecoder(res.Body).Decode(&r); err != nil {
		return Release{}, fmt.Errorf("cannot decode JSON: %w", err)
	}
	return r, nil
}

func buildFormula(name string, spec Spec, r Release) (Formula, error) {
	version := strings.TrimPrefix(r.Tag, "v")
	formula := Formula{Spec: spec, Name: name, Class: class(name), Version: version}

	var problems []string
	for _, p := range platforms {
		if spec.MacOnly && !p.Mac {
			continue
		}
		asset := fmt.Sprintf("%s-v%s-%s.tar.gz", name, version, p.Suffix)
		i := slices.IndexFunc(r.Assets, func(a Asset) bool { return a.Name == asset })
		if i < 0 {
			problems = append(problems, asset+" is missing")
			continue
		}
		a := r.Assets[i]
		// digest is only set on assets uploaded since mid-2025.
		sha, ok := strings.CutPrefix(a.Digest, "sha256:")
		if !ok {
			problems = append(problems, asset+" has no sha256 digest")
			continue
		}
		formula.Files = append(formula.Files, File{SHA256: sha, Platform: p})
	}
	if len(problems) > 0 {
		return Formula{}, fmt.Errorf("%s %s: %s", name, r.Tag, strings.Join(problems, ", "))
	}

	return formula, nil
}

// class turns a formula name into its Ruby class name: git-get -> GitGet.
func class(name string) string {
	var b strings.Builder
	for _, p := range strings.Split(name, "-") {
		b.WriteString(strings.ToUpper(p[:1]) + p[1:])
	}
	return b.String()
}

// indent prefixes each non-blank line of s with n spaces.
func indent(n int, s string) string {
	pad := strings.Repeat(" ", n)
	lines := strings.Split(s, "\n")
	for i, l := range lines {
		if l != "" {
			lines[i] = pad + l
		}
	}
	return strings.Join(lines, "\n")
}

func renderFormula(formula Formula) (string, error) {
	t, err := template.New("formula").Funcs(template.FuncMap{"indent": indent, "join": strings.Join}).Parse(tmpl)
	if err != nil {
		return "", err
	}
	var buf strings.Builder
	if err := t.Execute(&buf, formula); err != nil {
		return "", err
	}
	return buf.String(), nil
}

const tmpl = `# This file was generated by tools/formulae. DO NOT EDIT.
class {{ .Class }} < Formula
  desc "{{ .Desc }}"
  homepage "https://github.com/{{ .Repo }}"
  version "{{ .Version }}"
{{- if .MacOnly }}
  depends_on :macos
{{- end }}
{{ range .Files }}
  if {{ .Platform.Condition }}
    url "https://github.com/{{ $.Repo }}/releases/download/v#{version}/{{ $.Name }}-v#{version}-{{ .Platform.Suffix }}.tar.gz"
    sha256 "{{ .SHA256 }}"
  end
{{ end }}
{{ if .Conflicts }}{{ range .Conflicts }}  conflicts_with "{{ . }}"
{{ end }}
{{ end }}  def install
{{ indent 4 (join .Install "\n") }}
  end

  test do
{{ indent 4 .Test }}
  end
end
`
