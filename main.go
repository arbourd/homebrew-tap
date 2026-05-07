package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"text/template"
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

const URL = "https://go.dev/dl/"

var osArchMap = map[string]map[string]OSArch{
	"darwin": {"arm64": DarwinArm64, "amd64": DarwinAmd64},
	"linux":  {"amd64": LinuxAmd64, "arm64": LinuxArm64, "armv6l": LinuxArm},
}

func main() {
	res, err := http.Get(URL + "?mode=json")
	if err != nil {
		log.Fatalf("cannot get Go release: %v", err)
	}
	defer res.Body.Close()

	body, err := io.ReadAll(res.Body)
	if err != nil {
		log.Fatalf("cannot parse response body: %v", err)
	}

	r := []Release{}
	err = json.Unmarshal(body, &r)
	if err != nil {
		log.Fatalf("cannot unmarshal JSON: %v", err)
	}
	formula := buildFormula(r[0])

	s, err := renderFormula(formula)
	if err != nil {
		log.Fatalf("cannot render formula: %v", err)
	}
	fmt.Print(s)
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
	formula := Formula{Version: processVersion(latest.Version)}
	for _, f := range latest.Files {
		if f.Kind != "archive" {
			continue
		}

		osArch, ok := osArchMap[f.OS][f.Arch]
		if !ok {
			continue
		}

		formula.Files = append(formula.Files, File{
			URL:    URL + f.Filename,
			SHA256: f.SHA256,
			OSArch: osArch,
		})
	}

	return formula
}

// processVersion strips the "go" prefix from the version string.
// Vestigial from the original go formula, kept for compatibility.
func processVersion(v string) string {
	return strings.TrimPrefix(v, "go")
}

const tmpl = `class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "{{ .Version }}"
{{ range $f := .Files -}}
{{- if eq .OSArch 0 }}
  if OS.mac? && Hardware::CPU.arm?
{{- else if eq .OSArch 1 }}
  if OS.mac? && Hardware::CPU.intel?
{{- else if eq .OSArch 2 }}
  if OS.linux? && Hardware::CPU.intel?
{{- else if eq .OSArch 3 }}
  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
{{- else if eq .OSArch 4 }}
  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
{{- end }}
    url "{{ $f.URL }}"
    sha256 "{{ $f.SHA256 }}"
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
    # This is a a bare minimum of go working as it uses fmt, build, and run.
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
