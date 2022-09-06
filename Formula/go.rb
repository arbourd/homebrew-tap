class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.19.1"

  if OS.mac?
    url "https://go.dev/dl/go1.19.1.darwin-amd64.tar.gz"
    sha256 "b2828a2b05f0d2169afc74c11ed010775bf7cf0061822b275697b2f470495fb7"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.19.1.darwin-arm64.tar.gz"
    sha256 "e46aecce83a9289be16ce4ba9b8478a5b89b8aa0230171d5c6adbc0c66640548"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.19.1.linux-amd64.tar.gz"
    sha256 "acc512fbab4f716a8f97a8b3fbaa9ddd39606a28be6c2515ef7c6c6311acffde"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.19.1.linux-arm64.tar.gz"
    sha256 "49960821948b9c6b14041430890eccee58c76b52e2dbaafce971c3c38d43df9f"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.19.1.linux-armv6l.tar.gz"
    sha256 "efe93f5671621ee84ce5e262e1e21acbc72acefbaba360f21778abd083d4ad16"
  end

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
