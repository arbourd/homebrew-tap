class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.18.4"

  if OS.mac?
    url "https://go.dev/dl/go1.18.4.darwin-amd64.tar.gz"
    sha256 "315e1a2b21a827c68da1b7f492b5dcbe81d8df8a79ebe50922df9588893f87f0"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.18.4.darwin-arm64.tar.gz"
    sha256 "04eed623d5143ffa44965b618b509e0beccccfd3a4a1bfebc0cdbcf906046769"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.18.4.linux-amd64.tar.gz"
    sha256 "c9b099b68d93f5c5c8a8844a89f8db07eaa58270e3a1e01804f17f4cf8df02f5"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.18.4.linux-arm64.tar.gz"
    sha256 "35014d92b50d97da41dade965df7ebeb9a715da600206aa59ce1b2d05527421f"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.18.4.linux-armv6l.tar.gz"
    sha256 "7dfeab572e49638b0f3d9901457f0622c27b73301c2b99db9f5e9568ff40460c"
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
