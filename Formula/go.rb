class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.25.0"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.25.0.darwin-amd64.tar.gz"
    sha256 "5bd60e823037062c2307c71e8111809865116714d6f6b410597cf5075dfd80ef"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.25.0.darwin-arm64.tar.gz"
    sha256 "544932844156d8172f7a28f77f2ac9c15a23046698b6243f633b0a0b00c0749c"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.25.0.linux-amd64.tar.gz"
    sha256 "2852af0cb20a13139b3448992e69b868e50ed0f8a1e5940ee1de9e19a123b613"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.25.0.linux-arm64.tar.gz"
    sha256 "05de75d6994a2783699815ee553bd5a9327d8b79991de36e38b66862782f54ae"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.25.0.linux-armv6l.tar.gz"
    sha256 "a5a8f8198fcf00e1e485b8ecef9ee020778bf32a408a4e8873371bfce458cd09"
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
