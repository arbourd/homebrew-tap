class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.18.5"

  if OS.mac?
    url "https://go.dev/dl/go1.18.5.darwin-amd64.tar.gz"
    sha256 "828eeca8b5abea3e56921df8fa4b1101380a5ebcfee10acbc8ffe7ec0bf5876b"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.18.5.darwin-arm64.tar.gz"
    sha256 "923a377c6fc9a2c789f5db61c24b8f64133f7889056897449891f256af34065f"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.18.5.linux-amd64.tar.gz"
    sha256 "9e5de37f9c49942c601b191ac5fba404b868bfc21d446d6960acc12283d6e5f2"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.18.5.linux-arm64.tar.gz"
    sha256 "006f6622718212363fa1ff004a6ab4d87bbbe772ec5631bab7cac10be346e4f1"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.18.5.linux-armv6l.tar.gz"
    sha256 "d5ac34ac5f060a5274319aa04b7b11e41b123bd7887d64efb5f44ead236957af"
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
