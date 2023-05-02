class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.20.4"

  if OS.mac?
    url "https://go.dev/dl/go1.20.4.darwin-amd64.tar.gz"
    sha256 "242b099b5b9bd9c5d4d25c041216bc75abcdf8e0541aec975eeabcbce61ad47f"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.20.4.darwin-arm64.tar.gz"
    sha256 "61bd4f7f2d209e2a6a7ce17787fc5fea52fb11cc9efb3d8471187a8b39ce0dc9"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.20.4.linux-amd64.tar.gz"
    sha256 "698ef3243972a51ddb4028e4a1ac63dc6d60821bf18e59a807e051fee0a385bd"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.4.linux-arm64.tar.gz"
    sha256 "105889992ee4b1d40c7c108555222ca70ae43fccb42e20fbf1eebb822f5e72c6"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.4.linux-armv6l.tar.gz"
    sha256 "0b75ca23061a9996840111f5f19092a1bdbc42ec1ae25237ed2eec1c838bd819"
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
