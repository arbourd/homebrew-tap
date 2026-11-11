package main

import (
	"fmt"
	"regexp"
	"slices"
	"strings"
)

const goDL = "https://go.dev/dl/"

type goFile struct {
	Filename string `json:"filename"`
	SHA256   string `json:"sha256"`
	Kind     string `json:"kind"`
}

type goRelease struct {
	Version string   `json:"version"`
	Files   []goFile `json:"files"`
}

// These values are written into Formula/go.rb and the PR, so reject anything unexpected.
var goVersionRe = regexp.MustCompile(`^go[0-9]+\.[0-9]+(\.[0-9]+)?$`)

// fetchGoReleases retrieves the release list from url, trying up to maxAttempts times.
func fetchGoReleases(url string) ([]goRelease, error) {
	return getJSON[[]goRelease](url, nil)
}

func buildGoFormula(name string, spec Spec, r goRelease) (Formula, error) {
	if !goVersionRe.MatchString(r.Version) {
		return Formula{}, fmt.Errorf("invalid version %q", r.Version)
	}
	formula := Formula{Spec: spec, Name: name, Class: class(name), Version: strings.TrimPrefix(r.Version, "go")}
	var missing []string
	for _, p := range platforms {
		asset, ok := spec.Platforms[p.Suffix]
		if !ok {
			continue
		}
		filename := strings.ReplaceAll(asset, "#{version}", formula.Version)
		i := slices.IndexFunc(r.Files, func(f goFile) bool { return f.Kind == "archive" && f.Filename == filename })
		if i < 0 {
			missing = append(missing, filename)
			continue
		}
		f := r.Files[i]
		if !sha256Re.MatchString(f.SHA256) {
			return Formula{}, fmt.Errorf("invalid sha256 %q for %s", f.SHA256, f.Filename)
		}
		formula.Files = append(formula.Files, File{SHA256: f.SHA256, Platform: p, URL: goDL + filename})
	}
	if len(missing) > 0 {
		return Formula{}, fmt.Errorf("%s has no archive for: %s", r.Version, strings.Join(missing, ", "))
	}
	return formula, nil
}
