class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.23.4"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.23.4.darwin-amd64.tar.gz"
    sha256 "6700067389a53a1607d30aa8d6e01d198230397029faa0b109e89bc871ab5a0e"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.23.4.darwin-arm64.tar.gz"
    sha256 "87d2bb0ad4fe24d2a0685a55df321e0efe4296419a9b3de03369dbe60b8acd3a"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.23.4.linux-amd64.tar.gz"
    sha256 "6924efde5de86fe277676e929dc9917d466efa02fb934197bc2eba35d5680971"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.23.4.linux-arm64.tar.gz"
    sha256 "16e5017863a7f6071363782b1b8042eb12c6ca4f4cd71528b2123f0a1275b13e"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.23.4.linux-armv6l.tar.gz"
    sha256 "1f1dda0dc7ce0b2295f57258ec5ef0803fd31b9ed0aa20e2e9222334e5755de1"
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

    with_env(GOOS: "freebsd", GOARCH: "amd64") do
      system bin/"go", "build", "hello.go"
    end

    (testpath/"hello_cgo.go").write <<~EOS
      package main

      /*
      #include <stdlib.h>
      #include <stdio.h>
      void hello() { printf("%s\\n", "Hello from cgo!"); fflush(stdout); }
      */
      import "C"

      func main() {
          C.hello()
      }
    EOS

    # Try running a sample using cgo without CC or CXX set to ensure that the
    # toolchain's default choice of compilers work
    with_env(CC: nil, CXX: nil) do
      assert_equal "Hello from cgo!\n", shell_output("#{bin}/go run hello_cgo.go")
    end
  end
end
