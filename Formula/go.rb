class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.19.4"

  if OS.mac?
    url "https://go.dev/dl/go1.19.4.darwin-amd64.tar.gz"
    sha256 "44894862d996eec96ef2a39878e4e1fce4d05423fc18bdc1cbba745ebfa41253"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.19.4.darwin-arm64.tar.gz"
    sha256 "bb3bc5d7655b9637cfe2b5e90055dee93b0ead50e2ffd091df320d1af1ca853f"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.19.4.linux-amd64.tar.gz"
    sha256 "c9c08f783325c4cf840a94333159cc937f05f75d36a8b307951d5bd959cf2ab8"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.19.4.linux-arm64.tar.gz"
    sha256 "9df122d6baf6f2275270306b92af3b09d7973fb1259257e284dba33c0db14f1b"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.19.4.linux-armv6l.tar.gz"
    sha256 "7a51dae4f3a52d2dfeaf59367cc0b8a296deddc87e95aa619bf87d24661d2370"
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
