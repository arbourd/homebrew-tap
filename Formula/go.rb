class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.20.3"

  if OS.mac?
    url "https://go.dev/dl/go1.20.3.darwin-amd64.tar.gz"
    sha256 "c1e1161d6d859deb576e6cfabeb40e3d042ceb1c6f444f617c3c9d76269c3565"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.20.3.darwin-arm64.tar.gz"
    sha256 "86b0ed0f2b2df50fa8036eea875d1cf2d76cefdacf247c44639a1464b7e36b95"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.20.3.linux-amd64.tar.gz"
    sha256 "979694c2c25c735755bf26f4f45e19e64e4811d661dd07b8c010f7a8e18adfca"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.3.linux-arm64.tar.gz"
    sha256 "eb186529f13f901e7a2c4438a05c2cd90d74706aaa0a888469b2a4a617b6ee54"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.3.linux-armv6l.tar.gz"
    sha256 "b421e90469a83671641f81b6e20df6500f033e9523e89cbe7b7223704dd1035c"
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
