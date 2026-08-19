class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.27.0"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.27.0.darwin-amd64.tar.gz"
    sha256 "d3314e25496e4381d71a5c51d2907e7af655d199f6780b549f015bd85fef4986"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.27.0.darwin-arm64.tar.gz"
    sha256 "90493b3bbd5e10f91d12153198bf1994fd756399b4fec93b49b0c6e2acdeeb3e"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.27.0.linux-amd64.tar.gz"
    sha256 "675c26c449cbb18fc24b74650de1eabbae6e16f64326fd85a283fb3b58280685"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.27.0.linux-arm64.tar.gz"
    sha256 "51798d2c42d0e1c6ed7fd9f48728b4193abac9e8aad6dbac2fe96a81f5909bda"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.27.0.linux-armv6l.tar.gz"
    sha256 "e337ecd9c321377c0d8832690c2cb10463447c0bd0e65e2e3413dfff63a3435b"
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
