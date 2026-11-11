// Command formulae prints Homebrew formulae for the projects in formulae.yaml, built from each
// project's latest release (GitHub, or go.dev for `source: go`).
//
// Usage:
//
//	formulae <name>                    print the formula for <name>
//	formulae --list                    print every name as a JSON array
//	formulae --notes <name> <version>  print the release notes URL for <version>
package main

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"fmt"
	"log"
	"maps"
	"net/http"
	"os"
	"regexp"
	"slices"
	"strings"
	"text/template"
	"time"

	"gopkg.in/yaml.v3"
)

// Spec describes a formula. Releases come from GitHub (`source: github`), with each supported
// platform's asset named in Platforms. Source "go" reads go.dev instead, with Platforms naming
// go.dev files.
type Spec struct {
	Source   string `yaml:"source"`
	Repo     string `yaml:"repo"`
	Desc     string `yaml:"desc"`
	Homepage string `yaml:"homepage"`
	// ReleaseNotes is the PR body link; `#{version}` is replaced by the version.
	ReleaseNotes string   `yaml:"release_notes"`
	Conflicts    []string `yaml:"conflicts"`
	// Platforms maps a platform suffix (e.g. darwin-arm64) to its release asset (or go.dev
	// file) name, with `#{version}`. A platform is supported if and only if it is listed.
	Platforms map[string]string `yaml:"platforms"`
	Install   []string          `yaml:"install"`
	Test      string            `yaml:"test"`
}

// Platform is one release target. Suffix is the `<os>-<arch>` key used in `platforms`.
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
	URL      string
}

type Formula struct {
	Spec
	Name    string
	Class   string
	Version string
	Files   []File
}

// MacOnly reports whether the formula has no Linux file.
func (f Formula) MacOnly() bool {
	return !slices.ContainsFunc(f.Files, func(file File) bool { return !file.Platform.Mac })
}

// archOnly returns the Homebrew arch (arm64 or intel) when the formula has exactly one file for
// the OS, and "" otherwise.
func (f Formula) archOnly(mac bool) string {
	var only []File
	for _, file := range f.Files {
		if file.Platform.Mac == mac {
			only = append(only, file)
		}
	}
	if len(only) != 1 {
		return ""
	}
	if strings.HasSuffix(only[0].Platform.Suffix, "arm64") {
		return "arm64"
	}
	return "intel"
}

// MacArch is the only macOS arch the formula supports, or "" if it supports both or neither.
func (f Formula) MacArch() string { return f.archOnly(true) }

// LinuxArch is the only Linux arch the formula supports, or "" if it supports both or neither.
func (f Formula) LinuxArch() string { return f.archOnly(false) }

// LinuxOnly reports whether the formula has no macOS file.
func (f Formula) LinuxOnly() bool {
	return !slices.ContainsFunc(f.Files, func(file File) bool { return file.Platform.Mac })
}

const (
	requestTimeout = 10 * time.Second
	maxAttempts    = 3
)

// retryDelay is the base wait between attempts; it grows linearly. A var so tests can zero it.
var retryDelay = time.Second

// sha256Re checks the digests written into formulae.
var sha256Re = regexp.MustCompile(`^[0-9a-f]{64}$`)

//go:embed formulae.yaml
var specsYAML []byte

var specs = loadSpecs()

func loadSpecs() map[string]Spec {
	m, err := parseSpecs(specsYAML)
	if err != nil {
		panic(err)
	}
	return m
}

// parseSpecs decodes and validates the registry, filling in the default release notes.
func parseSpecs(src []byte) (map[string]Spec, error) {
	var m map[string]Spec
	dec := yaml.NewDecoder(bytes.NewReader(src))
	dec.KnownFields(true)
	if err := dec.Decode(&m); err != nil {
		return nil, fmt.Errorf("cannot parse formulae.yaml: %w", err)
	}
	for name, spec := range m {
		if err := validateEntry(name, spec); err != nil {
			return nil, fmt.Errorf("formulae.yaml: %s: %w", name, err)
		}
		if spec.ReleaseNotes == "" {
			spec.ReleaseNotes = "https://github.com/" + spec.Repo + "/releases/tag/v#{version}"
			m[name] = spec
		}
	}
	return m, nil
}

// nameRe matches the schema's propertyNames pattern.
var nameRe = regexp.MustCompile(`^[a-z][a-z0-9]*(-[a-z0-9]+)*$`)

func validateEntry(name string, s Spec) error {
	if !nameRe.MatchString(name) {
		return fmt.Errorf("name must start with a letter and be lowercase words joined by single hyphens")
	}
	return s.validate()
}

// repoRe matches the schema's repo pattern.
var repoRe = regexp.MustCompile(`^[^/]+/[^/]+$`)

func (s Spec) validate() error {
	switch {
	case s.Source != "github" && s.Source != "go":
		return fmt.Errorf("source must be github or go, got %q", s.Source)
	case s.Source == "go" && (s.Repo != "" || s.Conflicts != nil):
		return fmt.Errorf("repo and conflicts do not apply to source go")
	case s.Homepage == "":
		return fmt.Errorf("homepage is required")
	case s.Source == "go" && s.ReleaseNotes == "":
		return fmt.Errorf("release_notes is required for source go")
	case s.ReleaseNotes != "" && !strings.Contains(s.ReleaseNotes, "#{version}"):
		return fmt.Errorf("release_notes must contain #{version}")
	case s.Source == "github" && !repoRe.MatchString(s.Repo):
		return fmt.Errorf("repo %q must be owner/name", s.Repo)
	case s.Desc == "":
		return fmt.Errorf("desc is required")
	case len(s.Install) == 0:
		return fmt.Errorf("install is required")
	case s.Test == "":
		return fmt.Errorf("test is required")
	case slices.Contains(s.Install, ""):
		return fmt.Errorf("install lines must not be empty")
	}
	if len(s.Platforms) == 0 {
		return fmt.Errorf("platforms is required")
	}
	for _, suffix := range slices.Sorted(maps.Keys(s.Platforms)) {
		if !slices.ContainsFunc(platforms, func(p Platform) bool { return p.Suffix == suffix }) {
			return fmt.Errorf("unknown platform %q", suffix)
		}
		if asset := s.Platforms[suffix]; asset == "" || strings.Contains(asset, "/") {
			return fmt.Errorf("platforms %s: asset %q must be a non-empty file name", suffix, asset)
		}
	}
	return nil
}

func main() {
	switch {
	case len(os.Args) == 2 && os.Args[1] == "--list":
		if err := json.NewEncoder(os.Stdout).Encode(names()); err != nil {
			log.Fatal(err)
		}
		return
	case len(os.Args) == 4 && os.Args[1] == "--notes":
		spec, ok := specs[os.Args[2]]
		if !ok {
			log.Fatalf("unknown formula %q; names: %s", os.Args[2], strings.Join(names(), ", "))
		}
		fmt.Println(strings.ReplaceAll(spec.ReleaseNotes, "#{version}", os.Args[3]))
		return
	case len(os.Args) != 2:
		log.Fatalf("usage: formulae <name> | --list | --notes <name> <version>; names: %s", strings.Join(names(), ", "))
	}
	name := os.Args[1]
	spec, ok := specs[name]
	if !ok {
		log.Fatalf("unknown formula %q; names: %s", name, strings.Join(names(), ", "))
	}

	formula, err := latest(name, spec)
	if err != nil {
		log.Fatalf("cannot build %s: %v", name, err)
	}
	s, err := renderFormula(formula)
	if err != nil {
		log.Fatalf("cannot render formula: %v", err)
	}
	fmt.Print(s)
}

// latest builds the formula for the newest release from the spec's source.
func latest(name string, spec Spec) (Formula, error) {
	if spec.Source == "go" {
		r, err := fetchGoReleases(goDL + "?mode=json")
		if err != nil {
			return Formula{}, err
		}
		if len(r) == 0 {
			return Formula{}, fmt.Errorf("no Go releases found")
		}
		return buildGoFormula(name, spec, r[0])
	}
	r, err := fetchRelease("https://api.github.com/repos/" + spec.Repo + "/releases/latest")
	if err != nil {
		return Formula{}, err
	}
	return buildFormula(name, spec, r)
}

func names() []string {
	n := make([]string, 0, len(specs))
	for k := range specs {
		n = append(n, k)
	}
	slices.Sort(n)
	return n
}

// getJSON decodes the JSON at url, trying up to maxAttempts times.
func getJSON[T any](url string, setHeaders func(*http.Request)) (T, error) {
	client := &http.Client{Timeout: requestTimeout}

	var err error
	for attempt := 1; attempt <= maxAttempts; attempt++ {
		var v T
		if v, err = getJSONOnce[T](client, url, setHeaders); err == nil {
			return v, nil
		}
		log.Printf("attempt %d/%d failed: %v", attempt, maxAttempts, err)
		if attempt < maxAttempts {
			time.Sleep(time.Duration(attempt) * retryDelay)
		}
	}
	var zero T
	return zero, err
}

func getJSONOnce[T any](client *http.Client, url string, setHeaders func(*http.Request)) (T, error) {
	var v T
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return v, err
	}
	if setHeaders != nil {
		setHeaders(req)
	}

	res, err := client.Do(req)
	if err != nil {
		return v, err
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		return v, fmt.Errorf("GET %s: unexpected status: %s", url, res.Status)
	}
	if err := json.NewDecoder(res.Body).Decode(&v); err != nil {
		return v, fmt.Errorf("GET %s: cannot decode JSON: %w", url, err)
	}
	return v, nil
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
  homepage "{{ .Homepage }}"
  version "{{ .Version }}"
{{- if .MacOnly }}
  depends_on :macos
{{- else if .LinuxOnly }}
  depends_on :linux
{{- end }}
{{- with .MacArch }}
  on_macos do
    depends_on arch: :{{ . }}
  end
{{- end }}
{{- with .LinuxArch }}
  on_linux do
    depends_on arch: :{{ . }}
  end
{{- end }}
{{ range .Files }}
  if {{ .Platform.Condition }}
    url "{{ .URL }}"
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
