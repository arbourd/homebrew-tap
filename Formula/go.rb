class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.19.5"

  if OS.mac?
    url "https://go.dev/dl/go1.19.5.darwin-amd64.tar.gz"
    sha256 "23d22bb6571bbd60197bee8aaa10e702f9802786c2e2ddce5c84527e86b66aa0"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.19.5.darwin-arm64.tar.gz"
    sha256 "4a67f2bf0601afe2177eb58f825adf83509511d77ab79174db0712dc9efa16c8"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.19.5.linux-amd64.tar.gz"
    sha256 "36519702ae2fd573c9869461990ae550c8c0d955cd28d2827a6b159fda81ff95"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.19.5.linux-arm64.tar.gz"
    sha256 "fc0aa29c933cec8d76f5435d859aaf42249aa08c74eb2d154689ae44c08d23b3"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.19.5.linux-armv6l.tar.gz"
    sha256 "ec14f04bdaf4a62bdcf8b55b9b6434cc27c2df7d214d0bb7076a7597283b026a"
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
