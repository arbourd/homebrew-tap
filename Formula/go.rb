class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.20.7"

  if OS.mac?
    url "https://go.dev/dl/go1.20.7.darwin-amd64.tar.gz"
    sha256 "785170eab380a8985d53896808b0a71336d0ea60e0a26099b4ccec77798b1cf4"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.20.7.darwin-arm64.tar.gz"
    sha256 "eea1e7e4c2f75c72629050e6a6c7c46c446d64056732a7787fb3ba16ace1982e"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.20.7.linux-amd64.tar.gz"
    sha256 "f0a87f1bcae91c4b69f8dc2bc6d7e6bfcd7524fceec130af525058c0c17b1b44"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.7.linux-arm64.tar.gz"
    sha256 "44781ae3b153c3b07651d93b6bc554e835a36e2d72a696281c1e4dad9efffe43"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.7.linux-armv6l.tar.gz"
    sha256 "7cc231b415b94f2f7065870a73f67dd2b0ec12b5a98052b7ee0121c42bc04f8d"
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
