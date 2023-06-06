class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.20.5"

  if OS.mac?
    url "https://go.dev/dl/go1.20.5.darwin-amd64.tar.gz"
    sha256 "79715ca5b8becd120703ac9af5d1da749e095d2b9bf830c4f3af4b15b2cb049d"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.20.5.darwin-arm64.tar.gz"
    sha256 "94ad76b7e1593bb59df7fd35a738194643d6eed26a4181c94e3ee91381e40459"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.20.5.linux-amd64.tar.gz"
    sha256 "d7ec48cde0d3d2be2c69203bc3e0a44de8660b9c09a6e85c4732a3f7dc442612"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.5.linux-arm64.tar.gz"
    sha256 "aa2fab0a7da20213ff975fa7876a66d47b48351558d98851b87d1cfef4360d09"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.5.linux-armv6l.tar.gz"
    sha256 "79d8210efd4390569912274a98dffc16eb85993cccdeef4d704e9b0dfd50743a"
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
