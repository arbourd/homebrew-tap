class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.18.1"

  if OS.mac?
    url "https://go.dev/dl/go1.18.1.darwin-amd64.tar.gz"
    sha256 "3703e9a0db1000f18c0c7b524f3d378aac71219b4715a6a4c5683eb639f41a4d"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.18.1.darwin-arm64.tar.gz"
    sha256 "6d5641a06edba8cd6d425fb0adad06bad80e2afe0fa91b4aa0e5aed1bc78f58e"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.18.1.linux-amd64.tar.gz"
    sha256 "b3b815f47ababac13810fc6021eb73d65478e0b2db4b09d348eefad9581a2334"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.18.1.linux-arm64.tar.gz"
    sha256 "56a91851c97fb4697077abbca38860f735c32b38993ff79b088dac46e4735633"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.18.1.linux-armv6l.tar.gz"
    sha256 "9edc01c8e7db64e9ceeffc8258359e027812886ceca3444e83c4eb96ddb068ee"
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
