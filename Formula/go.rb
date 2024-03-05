class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.22.1"

  if OS.mac?
    url "https://go.dev/dl/go1.22.1.darwin-amd64.tar.gz"
    sha256 "3bc971772f4712fec0364f4bc3de06af22a00a12daab10b6f717fdcd13156cc0"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.22.1.darwin-arm64.tar.gz"
    sha256 "f6a9cec6b8a002fcc9c0ee24ec04d67f430a52abc3cfd613836986bcc00d8383"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.22.1.linux-amd64.tar.gz"
    sha256 "aab8e15785c997ae20f9c88422ee35d962c4562212bb0f879d052a35c8307c7f"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.22.1.linux-arm64.tar.gz"
    sha256 "e56685a245b6a0c592fc4a55f0b7803af5b3f827aaa29feab1f40e491acf35b8"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.22.1.linux-armv6l.tar.gz"
    sha256 "8cb7a90e48c20daed39a6ac8b8a40760030ba5e93c12274c42191d868687c281"
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
