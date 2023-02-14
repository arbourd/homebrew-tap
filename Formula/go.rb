class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.20.1"

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.20.1.linux-amd64.tar.gz"
    sha256 "000a5b1fca4f75895f78befeb2eecf10bfff3c428597f3f1e69133b63b911b02"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.1.linux-arm64.tar.gz"
    sha256 "5e5e2926733595e6f3c5b5ad1089afac11c1490351855e87849d0e7702b1ec2e"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.1.linux-armv6l.tar.gz"
    sha256 "e4edc05558ab3657ba3dddb909209463cee38df9c1996893dd08cde274915003"
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
