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
	"cmp"
	_ "embed"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"regexp"
	"slices"
	"strings"
	"text/template"
	"time"

	"gopkg.in/yaml.v3"
)

// Spec describes a formula. Releases come from GitHub (the default source) and follow GoReleaser's
// `<name>-v<ver>-<os>-<arch>.tar.gz` layout unless URLs overrides them. Source "go" reads go.dev instead.
type Spec struct {
	Source   string `yaml:"source"`
	Repo     string `yaml:"repo"`
	Homepage string `yaml:"homepage"`
	// ReleaseNotes is the PR body link; `#{version}` is replaced by the version.
	ReleaseNotes string   `yaml:"release_notes"`
	Desc         string   `yaml:"desc"`
	MacOnly      bool     `yaml:"mac_only"`
	Conflicts    []string `yaml:"conflicts"`
	Install      []string `yaml:"install"`
	Test         string   `yaml:"test"`
	// URLs maps a platform suffix (e.g. darwin-arm64) to its download URL, written as it appears
	// in the formula (with `#{version}`). Every non-skipped platform must be listed.
	URLs map[string]string `yaml:"urls"`
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
	URL      string
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

// sha256Re checks the digests written into formulae.
var sha256Re = regexp.MustCompile(`^[0-9a-f]{64}$`)

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
		if spec.Source == "" {
			repoURL := "https://github.com/" + spec.Repo
			spec.Homepage = cmp.Or(spec.Homepage, repoURL)
			spec.ReleaseNotes = cmp.Or(spec.ReleaseNotes, repoURL+"/releases/tag/v#{version}")
			m[name] = spec
		}
	}
	return m
}

func (s Spec) validate() error {
	switch {
	case s.Source != "" && s.Source != "go":
		return fmt.Errorf("unknown source %q", s.Source)
	case s.Source == "go" && (s.Repo != "" || s.URLs != nil || s.MacOnly || s.Conflicts != nil):
		return fmt.Errorf("repo, urls, mac_only and conflicts do not apply to source go")
	case s.Source == "go" && (s.Homepage == "" || s.ReleaseNotes == ""):
		return fmt.Errorf("homepage and release_notes are required for source go")
	case s.ReleaseNotes != "" && !strings.Contains(s.ReleaseNotes, "#{version}"):
		return fmt.Errorf("release_notes must contain #{version}")
	case s.Source == "" && (strings.Count(s.Repo, "/") != 1 || strings.HasPrefix(s.Repo, "/") || strings.HasSuffix(s.Repo, "/")):
		return fmt.Errorf("repo %q must be owner/name", s.Repo)
	case s.Desc == "":
		return fmt.Errorf("desc is required")
	case len(s.Install) == 0:
		return fmt.Errorf("install is required")
	case s.Test == "":
		return fmt.Errorf("test is required")
	}
	for _, p := range platforms {
		if s.URLs != nil && (!s.MacOnly || p.Mac) && s.URLs[p.Suffix] == "" {
			return fmt.Errorf("urls is missing %s", p.Suffix)
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
