class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.24.2"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.24.2.darwin-amd64.tar.gz"
    sha256 "238d9c065d09ff6af229d2e3b8b5e85e688318d69f4006fb85a96e41c216ea83"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.24.2.darwin-arm64.tar.gz"
    sha256 "b70f8b3c5b4ccb0ad4ffa5ee91cd38075df20fdbd953a1daedd47f50fbcff47a"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.24.2.linux-amd64.tar.gz"
    sha256 "68097bd680839cbc9d464a0edce4f7c333975e27a90246890e9f1078c7e702ad"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.24.2.linux-arm64.tar.gz"
    sha256 "756274ea4b68fa5535eb9fe2559889287d725a8da63c6aae4d5f23778c229f4b"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.24.2.linux-armv6l.tar.gz"
    sha256 "438d5d3d7dcb239b58d893a715672eabe670b9730b1fd1c8fc858a46722a598a"
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
