class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.26.3"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.26.3.darwin-amd64.tar.gz"
    sha256 "278d580b32e299fe4a9c990fcf2d02acfe538c7e551a6ee18f9c7164573d2c63"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.26.3.darwin-arm64.tar.gz"
    sha256 "875cf54a15311eee2c99b9dd67c68c4a49351d489ab622bf2cfd28c8f2078d3c"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.26.3.linux-amd64.tar.gz"
    sha256 "2b2cfc7148493da5e73981bffbf3353af381d5f93e789c82c79aff64962eb556"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.26.3.linux-arm64.tar.gz"
    sha256 "9d89a3ea57d141c2b22d70083f2c8459ba3890f2d9e818e7e933b75614936565"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.26.3.linux-armv6l.tar.gz"
    sha256 "d44133d4c66b1451a1e247da26db7716f76a081c0169a75e6c84e1871e394320"
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
