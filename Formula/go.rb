class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.21.2"

  if OS.mac?
    url "https://go.dev/dl/go1.21.2.darwin-amd64.tar.gz"
    sha256 "31db09a0ebaf89a3efa15a84cc67d4a8b60ae4aace9e6818e453d72be64f76bd"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.21.2.darwin-arm64.tar.gz"
    sha256 "7534d79f1955b57971092a91d2ce683fc49352c6130e2c9411357031c05437a4"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.21.2.linux-amd64.tar.gz"
    sha256 "f5414a770e5e11c6e9674d4cd4dd1f4f630e176d1828d3427ea8ca4211eee90d"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.2.linux-arm64.tar.gz"
    sha256 "23e208ca44a3cb46cd4308e48a27c714ddde9c8c34f2e4211dbca95b6d456554"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.21.2.linux-armv6l.tar.gz"
    sha256 "8727d842176a2bfd9edf307ed5411c39a69e2c6a748098987be361e8e0c36b46"
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
