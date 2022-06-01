class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.18.3"

  if OS.mac?
    url "https://go.dev/dl/go1.18.3.darwin-amd64.tar.gz"
    sha256 "d9dcf8fc35da54c6f259be41954783a9f4984945a855d03a003a7fd6ea4c5ca1"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.18.3.darwin-arm64.tar.gz"
    sha256 "40ecd383c941cc9f0682e6a6f2a333539d58c7dea15c842434d03afafe2f7242"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.18.3.linux-amd64.tar.gz"
    sha256 "956f8507b302ab0bb747613695cdae10af99bbd39a90cae522b7c0302cc27245"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.18.3.linux-arm64.tar.gz"
    sha256 "beacbe1441bee4d7978b900136d1d6a71d150f0a9bb77e9d50c822065623a35a"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.18.3.linux-armv6l.tar.gz"
    sha256 "b8f0b5db24114388d5dcba7ca0698510ea05228b0402fcbeb0881f74ae9cb83b"
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
