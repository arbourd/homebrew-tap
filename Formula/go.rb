class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.21.1"

  if OS.mac?
    url "https://go.dev/dl/go1.21.1.darwin-amd64.tar.gz"
    sha256 "809f5b0ef4f7dcdd5f51e9630a5b2e5a1006f22a047126d61560cdc365678a19"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.21.1.darwin-arm64.tar.gz"
    sha256 "ffd40391a1e995855488b008ad9326ff8c2e81803a6e80894401003bae47fcf1"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.21.1.linux-amd64.tar.gz"
    sha256 "b3075ae1ce5dab85f89bc7905d1632de23ca196bd8336afd93fa97434cfa55ae"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.1.linux-arm64.tar.gz"
    sha256 "7da1a3936a928fd0b2602ed4f3ef535b8cd1990f1503b8d3e1acc0fa0759c967"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.1.linux-armv6l.tar.gz"
    sha256 "f3716a43f59ae69999841d6007b42c9e286e8d8ce470656fb3e70d7be2d7ca85"
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
