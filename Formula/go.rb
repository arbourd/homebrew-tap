class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.20.2"

  if OS.mac?
    url "https://go.dev/dl/go1.20.2.darwin-amd64.tar.gz"
    sha256 "c93b8ced9517d07e1cd4c362c6e2d5242cb139e29b417a328fbf19aded08764c"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.20.2.darwin-arm64.tar.gz"
    sha256 "7343c87f19e79c0063532e82e1c4d6f42175a32d99f7a4d15e658e88bf97f885"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.20.2.linux-amd64.tar.gz"
    sha256 "4eaea32f59cde4dc635fbc42161031d13e1c780b87097f4b4234cfce671f1768"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.2.linux-arm64.tar.gz"
    sha256 "78d632915bb75e9a6356a47a42625fd1a785c83a64a643fedd8f61e31b1b3bef"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.20.2.linux-armv6l.tar.gz"
    sha256 "d79d56bafd6b52b8d8cbe3f8e967caaac5383a23d7a4fa9ac0e89778cd16a076"
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
