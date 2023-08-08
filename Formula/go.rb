class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.21.0"

  if OS.mac?
    url "https://go.dev/dl/go1.21.0.darwin-amd64.tar.gz"
    sha256 "b314de9f704ab122c077d2ec8e67e3670affe8865479d1f01991e7ac55d65e70"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.21.0.darwin-arm64.tar.gz"
    sha256 "3aca44de55c5e098de2f406e98aba328898b05d509a2e2a356416faacf2c4566"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.21.0.linux-amd64.tar.gz"
    sha256 "d0398903a16ba2232b389fb31032ddf57cac34efda306a0eebac34f0965a0742"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.0.linux-arm64.tar.gz"
    sha256 "f3d4548edf9b22f26bbd49720350bbfe59d75b7090a1a2bff1afad8214febaf3"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.0.linux-armv6l.tar.gz"
    sha256 "e377a0004957c8c560a3ff99601bce612330a3d95ba3b0a2ae144165fc87deb1"
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
