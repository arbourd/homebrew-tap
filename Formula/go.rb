class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.21.5"

  if OS.mac?
    url "https://go.dev/dl/go1.21.5.darwin-amd64.tar.gz"
    sha256 "a2e1d5743e896e5fe1e7d96479c0a769254aed18cf216cf8f4c3a2300a9b3923"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.21.5.darwin-arm64.tar.gz"
    sha256 "d0f8ac0c4fb3efc223a833010901d02954e3923cfe2c9a2ff0e4254a777cc9cc"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.21.5.linux-amd64.tar.gz"
    sha256 "e2bc0b3e4b64111ec117295c088bde5f00eeed1567999ff77bc859d7df70078e"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.5.linux-arm64.tar.gz"
    sha256 "841cced7ecda9b2014f139f5bab5ae31785f35399f236b8b3e75dff2a2978d96"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.5.linux-armv6l.tar.gz"
    sha256 "837f4bf4e22fcdf920ffeaa4abf3d02d1314e03725431065f4d44c46a01b42fe"
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
