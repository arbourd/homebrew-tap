class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.19.2"

  if OS.mac?
    url "https://go.dev/dl/go1.19.2.darwin-amd64.tar.gz"
    sha256 "16f8047d7b627699b3773680098fbaf7cc962b7db02b3e02726f78c4db26dfde"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.19.2.darwin-arm64.tar.gz"
    sha256 "35d819df25197c0be45f36ce849b994bba3b0559b76d4538b910d28f6395c00d"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.19.2.linux-amd64.tar.gz"
    sha256 "5e8c5a74fe6470dd7e055a461acda8bb4050ead8c2df70f227e3ff7d8eb7eeb6"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.19.2.linux-arm64.tar.gz"
    sha256 "b62a8d9654436c67c14a0c91e931d50440541f09eb991a987536cb982903126d"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.19.2.linux-armv6l.tar.gz"
    sha256 "f3ccec7816ecd704ebafd130b08b8ad97c55402a8193a107b63e9de12ab90118"
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
