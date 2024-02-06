class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.21.7"

  if OS.mac?
    url "https://go.dev/dl/go1.21.7.darwin-amd64.tar.gz"
    sha256 "4b9f4e02e465ba0f3a4c138ecb1c148135cf77c0efb5474461746b7c123b3484"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.21.7.darwin-arm64.tar.gz"
    sha256 "26e23304810f8e14ba443664326f53d7eafd83faa8097a5c2c4d55b61f431280"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.21.7.linux-amd64.tar.gz"
    sha256 "13b76a9b2a26823e53062fa841b07087d48ae2ef2936445dc34c4ae03293702c"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.7.linux-arm64.tar.gz"
    sha256 "a9bc1ccedbfde059f25b3a2ad81ae4cdf21192ae207dfd3ccbbfe99c3749e233"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.7.linux-armv6l.tar.gz"
    sha256 "d86d2da4cad1c0ff5fc13677b0b77f26ca8adca48170c140f06b882e83b6e8df"
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
