class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.24.3"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.24.3.darwin-amd64.tar.gz"
    sha256 "13e6fe3fcf65689d77d40e633de1e31c6febbdbcb846eb05fc2434ed2213e92b"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.24.3.darwin-arm64.tar.gz"
    sha256 "64a3fa22142f627e78fac3018ce3d4aeace68b743eff0afda8aae0411df5e4fb"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.24.3.linux-amd64.tar.gz"
    sha256 "3333f6ea53afa971e9078895eaa4ac7204a8c6b5c68c10e6bc9a33e8e391bdd8"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.24.3.linux-arm64.tar.gz"
    sha256 "a463cb59382bd7ae7d8f4c68846e73c4d589f223c589ac76871b66811ded7836"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.24.3.linux-armv6l.tar.gz"
    sha256 "17a392d7e826625dd12a32099df0b00b85c32d8132ed86fe917183ee5c3f88ed"
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
