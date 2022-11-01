class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.19.3"

  if OS.mac?
    url "https://go.dev/dl/go1.19.3.darwin-amd64.tar.gz"
    sha256 "7fa09a9a34cb6f794e61e9ada1d6d18796f936a2b35f22724906cad71396e590"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.19.3.darwin-arm64.tar.gz"
    sha256 "49e394ab92bc6fa3df3d27298ddf3e4491f99477bee9dd4934525a526f3a391c"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.19.3.linux-amd64.tar.gz"
    sha256 "74b9640724fd4e6bb0ed2a1bc44ae813a03f1e72a4c76253e2d5c015494430ba"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.19.3.linux-arm64.tar.gz"
    sha256 "99de2fe112a52ab748fb175edea64b313a0c8d51d6157dba683a6be163fd5eab"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.19.3.linux-armv6l.tar.gz"
    sha256 "d2f8028ff3e84b93265084394e4b8316138e8967864267392d7fa2d3e4623f82"
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
