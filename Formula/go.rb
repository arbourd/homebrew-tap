class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.24.6"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.24.6.darwin-amd64.tar.gz"
    sha256 "4a8d7a32052f223e71faab424a69430455b27b3fff5f4e651f9d97c3e51a8746"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.24.6.darwin-arm64.tar.gz"
    sha256 "4e29202c49573b953be7cc3500e1f8d9e66ddd12faa8cf0939a4951411e09a2a"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.24.6.linux-amd64.tar.gz"
    sha256 "bbca37cc395c974ffa4893ee35819ad23ebb27426df87af92e93a9ec66ef8712"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.24.6.linux-arm64.tar.gz"
    sha256 "124ea6033a8bf98aa9fbab53e58d134905262d45a022af3a90b73320f3c3afd5"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.24.6.linux-armv6l.tar.gz"
    sha256 "7feb4d25f5e72f94fda81c99d4adb6630dfa2c35211e0819417d53af6e71809e"
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
