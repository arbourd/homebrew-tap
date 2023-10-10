class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.21.3"

  if OS.mac?
    url "https://go.dev/dl/go1.21.3.darwin-amd64.tar.gz"
    sha256 "27014fc69e301d7588a169ca239b3cc609f0aa1abf38528bf0d20d3b259211eb"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.21.3.darwin-arm64.tar.gz"
    sha256 "65302a7a9f7a4834932b3a7a14cb8be51beddda757b567a2f9e0cbd0d7b5a6ab"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.21.3.linux-amd64.tar.gz"
    sha256 "1241381b2843fae5a9707eec1f8fb2ef94d827990582c7c7c32f5bdfbfd420c8"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.3.linux-arm64.tar.gz"
    sha256 "fc90fa48ae97ba6368eecb914343590bbb61b388089510d0c56c2dde52987ef3"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.3.linux-armv6l.tar.gz"
    sha256 "a1ddcaaf0821a12a800884c14cb4268ce1c1f5a0301e9060646f1e15e611c6c7"
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
