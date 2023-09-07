package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"text/template"
)

type Release struct {
	Version string `json:"version"`
	Files   []struct {
		Filename string `json:"filename"`
		OS       string `json:"os"`
		Arch     string `json:"arch"`
		SHA256   string `json:"sha256"`
		Kind     string `json:"kind"`
	} `json:"files"`
}

type Formula struct {
	Version string
	Files   []File
}

type OSArch int

const (
	DarwinAmd64 OSArch = iota
	DarwinArm64
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

func main() {
	res, err := http.Get(URL + "?mode=json")
	if err != nil {
		log.Fatal(fmt.Errorf("cannot get Go release: %s", err))
	}

	body, err := io.ReadAll(res.Body)
	if err != nil {
		log.Fatal(fmt.Errorf("cannot parse response body: %s", err))
	}

	r := []Release{}
	err = json.Unmarshal(body, &r)
	if err != nil {
		log.Fatal(fmt.Errorf("cannot unmarshal JSON: %s", err))
	}
	formula := buildFormula(r[0])

	f, err := os.Create("./Formula/go.rb")
	if err != nil {
		log.Fatal(fmt.Errorf("cannot open file: %s", err))
	}

	t := template.Must(template.New("formula").Parse(tmpl))
	err = t.Execute(f, formula)
	if err != nil {
		log.Fatal(fmt.Errorf("cannot write file: %s", err))
	}

	fmt.Println(formula.Version)
}

func buildFormula(latest Release) Formula {
	formula := Formula{Version: processVersion(latest.Version)}
	for _, f := range latest.Files {
		if f.Kind != "archive" {
			continue
		}

		file := File{
			URL:    URL + f.Filename,
			SHA256: f.SHA256,
		}

		if f.OS == "darwin" && f.Arch == "amd64" {
			file.OSArch = DarwinAmd64
		} else if f.OS == "darwin" && f.Arch == "arm64" {
			file.OSArch = DarwinArm64
		} else if f.OS == "linux" && f.Arch == "amd64" {
			file.OSArch = LinuxAmd64
		} else if f.OS == "linux" && f.Arch == "arm64" {
			file.OSArch = LinuxArm64
		} else if f.OS == "linux" && f.Arch == "armv6l" {
			file.OSArch = LinuxArm
		} else {
			continue
		}

		formula.Files = append(formula.Files, file)
	}

	return formula
}

func processVersion(v string) string {
	return strings.TrimPrefix(v, "go")
}

const tmpl = `class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "{{ .Version }}"
{{ range $f := .Files -}}
{{- if eq .OSArch 0 }}
  if OS.mac?
{{- else if eq .OSArch 1 }}
  if OS.mac? && Hardware::CPU.arm?
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

    ENV["GOOS"] = "freebsd"
    ENV["GOARCH"] = "amd64"
    system bin/"go", "build", "hello.go"
  end
end
`
