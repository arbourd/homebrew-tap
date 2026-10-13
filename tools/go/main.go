package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"text/template"
	"time"
)

type ReleaseFile struct {
	Filename string `json:"filename"`
	OS       string `json:"os"`
	Arch     string `json:"arch"`
	SHA256   string `json:"sha256"`
	Kind     string `json:"kind"`
}

type Release struct {
	Version string        `json:"version"`
	Files   []ReleaseFile `json:"files"`
}

type Formula struct {
	Version string
	Files   []File
}

type OSArch int

const (
	DarwinArm64 OSArch = iota
	DarwinAmd64
	LinuxAmd64
	LinuxArm64
	LinuxArm
)

type File struct {
	URL    string
	SHA256 string

	OSArch OSArch
}

// Condition returns the Homebrew condition that selects the platform.
func (o OSArch) Condition() string {
	switch o {
	case DarwinArm64:
		return "OS.mac? && Hardware::CPU.arm?"
	case DarwinAmd64:
		return "OS.mac? && Hardware::CPU.intel?"
	case LinuxAmd64:
		return "OS.linux? && Hardware::CPU.intel?"
	case LinuxArm64:
		return "OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?"
	case LinuxArm:
		return "OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?"
	}
	panic(fmt.Sprintf("unknown OSArch %d", int(o)))
}

const (
	baseURL        = "https://go.dev/dl/"
	requestTimeout = 10 * time.Second
	maxAttempts    = 3
)

var osArchMap = map[string]map[string]OSArch{
	"darwin": {"arm64": DarwinArm64, "amd64": DarwinAmd64},
	"linux":  {"amd64": LinuxAmd64, "arm64": LinuxArm64, "armv6l": LinuxArm},
}

func main() {
	r, err := fetchReleases()
	if err != nil {
		log.Fatalf("cannot get Go release: %v", err)
	}
	if len(r) == 0 {
		log.Fatal("no Go releases found")
	}
	formula := buildFormula(r[0])

	s, err := renderFormula(formula)
	if err != nil {
		log.Fatalf("cannot render formula: %v", err)
	}
	fmt.Print(s)
}

// fetchReleases retrieves the release list, trying up to maxAttempts times
// with a per-attempt timeout of requestTimeout.
func fetchReleases() ([]Release, error) {
	client := &http.Client{Timeout: requestTimeout}

	var err error
	for attempt := 1; attempt <= maxAttempts; attempt++ {
		var r []Release
		if r, err = fetchReleasesOnce(client); err == nil {
			return r, nil
		}
		log.Printf("attempt %d/%d failed: %v", attempt, maxAttempts, err)
	}
	return nil, err
}

func fetchReleasesOnce(client *http.Client) ([]Release, error) {
	res, err := client.Get(baseURL + "?mode=json")
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status: %s", res.Status)
	}

	var r []Release
	if err := json.NewDecoder(res.Body).Decode(&r); err != nil {
		return nil, fmt.Errorf("cannot decode JSON: %w", err)
	}
	return r, nil
}

func renderFormula(formula Formula) (string, error) {
	t, err := template.New("formula").Parse(tmpl)
	if err != nil {
		return "", err
	}
	var buf strings.Builder
	if err := t.Execute(&buf, formula); err != nil {
		return "", err
	}
	return buf.String(), nil
}

func buildFormula(latest Release) Formula {
	formula := Formula{Version: strings.TrimPrefix(latest.Version, "go")}
	for _, f := range latest.Files {
		if f.Kind != "archive" {
			continue
		}

		osArch, ok := osArchMap[f.OS][f.Arch]
		if !ok {
			continue
		}

		formula.Files = append(formula.Files, File{
			URL:    baseURL + f.Filename,
			SHA256: f.SHA256,
			OSArch: osArch,
		})
	}

	return formula
}

const tmpl = `class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "{{ .Version }}"
{{ range $f := .Files }}
  if {{ $f.OSArch.Condition }}
    url "{{ .URL }}"
    sha256 "{{ .SHA256 }}"
  end
{{ end }}
  def install
    libexec.install Dir["*"]
    bin.install_symlink Dir[libexec/"bin/go*"]
  end

  test do
    (testpath/"hello.go").write <<~EOS
      package main

      import "fmt"

      func main() {
          fmt.Println("Hello World")
      }
    EOS

    # Run go fmt check for no errors then run the program.
    # This is a bare minimum of go working as it uses fmt, build, and run.
    system bin/"go", "fmt", "hello.go"
    assert_equal "Hello World\n", shell_output("#{bin}/go run hello.go")

    with_env(GOOS: "freebsd", GOARCH: "amd64") do
      system bin/"go", "build", "hello.go"
    end

    (testpath/"hello_cgo.go").write <<~EOS
      package main

      /*
      #include <stdlib.h>
      #include <stdio.h>
      void hello() { printf("%s\\n", "Hello from cgo!"); fflush(stdout); }
      */
      import "C"

      func main() {
          C.hello()
      }
    EOS

    # Try running a sample using cgo without CC or CXX set to ensure that the
    # toolchain's default choice of compilers work
    with_env(CC: nil, CXX: nil) do
      assert_equal "Hello from cgo!\n", shell_output("#{bin}/go run hello_cgo.go")
    end
  end
end
`
