class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.21.4"

  if OS.mac?
    url "https://go.dev/dl/go1.21.4.darwin-amd64.tar.gz"
    sha256 "cd3bdcc802b759b70e8418bc7afbc4a65ca73a3fe576060af9fc8a2a5e71c3b8"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.21.4.darwin-arm64.tar.gz"
    sha256 "8b7caf2ac60bdff457dba7d4ff2a01def889592b834453431ae3caecf884f6a5"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.21.4.linux-amd64.tar.gz"
    sha256 "73cac0215254d0c7d1241fa40837851f3b9a8a742d0b54714cbdfb3feaf8f0af"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.4.linux-arm64.tar.gz"
    sha256 "ce1983a7289856c3a918e1fd26d41e072cc39f928adfb11ba1896440849b95da"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.4.linux-armv6l.tar.gz"
    sha256 "6c62e89113750cc77c498194d13a03fadfda22bd2c7d44e8a826fd354db60252"
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
