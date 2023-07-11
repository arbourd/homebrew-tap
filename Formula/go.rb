class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.20.6"

  if OS.mac?
    url "https://go.dev/dl/go1.20.6.darwin-amd64.tar.gz"
    sha256 "98a09c085b4c385abae7d35b9155195d5e584d14988347ac7f18e4cbe3b5ef3d"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.20.6.darwin-arm64.tar.gz"
    sha256 "1163be1998835a13f00dfc869a8e3cdebf86984ad41ff2fff43e35ac2a0d8344"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.20.6.linux-amd64.tar.gz"
    sha256 "b945ae2bb5db01a0fb4786afde64e6fbab50b67f6fa0eb6cfa4924f16a7ff1eb"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.6.linux-arm64.tar.gz"
    sha256 "4e15ab37556e979181a1a1cc60f6d796932223a0f5351d7c83768b356f84429b"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.6.linux-armv6l.tar.gz"
    sha256 "669902f5c8efefbd5d5fd078db01e34355af3693e48659b89593da7db367c488"
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
