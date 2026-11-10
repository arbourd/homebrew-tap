package main

import (
	"fmt"
	"net/http"
	"os"
	"path"
	"regexp"
	"slices"
	"strings"
)

// The tag is written into the formula and the PR, so reject anything unexpected.
var tagRe = regexp.MustCompile(`^v?[0-9]+\.[0-9]+(\.[0-9]+)?$`)

type Asset struct {
	Name   string `json:"name"`
	Digest string `json:"digest"`
}

type Release struct {
	Tag    string  `json:"tag_name"`
	Assets []Asset `json:"assets"`
}

// fetchRelease retrieves the latest release from url, trying up to maxAttempts times.
func fetchRelease(url string) (Release, error) {
	return getJSON[Release](url, func(req *http.Request) {
		req.Header.Set("Accept", "application/vnd.github+json")
		if token := os.Getenv("GITHUB_TOKEN"); token != "" {
			req.Header.Set("Authorization", "Bearer "+token)
		}
	})
}

func buildFormula(name string, spec Spec, r Release) (Formula, error) {
	if !tagRe.MatchString(r.Tag) {
		return Formula{}, fmt.Errorf("invalid tag %q", r.Tag)
	}
	version := strings.TrimPrefix(r.Tag, "v")
	formula := Formula{Spec: spec, Name: name, Class: class(name), Version: version}

	var problems []string
	for _, p := range platforms {
		if spec.MacOnly && !p.Mac {
			continue
		}
		url := fmt.Sprintf("https://github.com/%s/releases/download/v#{version}/%s-v#{version}-%s.tar.gz", spec.Repo, name, p.Suffix)
		if spec.URLs != nil {
			url = spec.URLs[p.Suffix]
		}
		asset := path.Base(strings.ReplaceAll(url, "#{version}", version))
		i := slices.IndexFunc(r.Assets, func(a Asset) bool { return a.Name == asset })
		if i < 0 {
			problems = append(problems, asset+" is missing")
			continue
		}
		a := r.Assets[i]
		// digest is only set on assets uploaded since mid-2025.
		sha, ok := strings.CutPrefix(a.Digest, "sha256:")
		if !ok || !sha256Re.MatchString(sha) {
			problems = append(problems, asset+" has no valid sha256 digest")
			continue
		}
		formula.Files = append(formula.Files, File{SHA256: sha, Platform: p, URL: url})
	}
	if len(problems) > 0 {
		return Formula{}, fmt.Errorf("%s %s: %s", name, r.Tag, strings.Join(problems, ", "))
	}

	return formula, nil
}
