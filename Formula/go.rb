class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.18"

  if OS.mac?
    url "https://go.dev/dl/go1.18.darwin-amd64.tar.gz"
    sha256 "70bb4a066997535e346c8bfa3e0dfe250d61100b17ccc5676274642447834969"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.18.darwin-arm64.tar.gz"
    sha256 "9cab6123af9ffade905525d79fc9ee76651e716c85f1f215872b5f2976782480"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.18.linux-amd64.tar.gz"
    sha256 "e85278e98f57cdb150fe8409e6e5df5343ecb13cebf03a5d5ff12bd55a80264f"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.18.linux-arm64.tar.gz"
    sha256 "7ac7b396a691e588c5fb57687759e6c4db84a2a3bbebb0765f4b38e5b1c5b00e"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.18.linux-armv6l.tar.gz"
    sha256 "a80fa43d1f4575fb030adbfbaa94acd860c6847820764eecb06c63b7c103612b"
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
