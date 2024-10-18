class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.23.2"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.23.2.darwin-amd64.tar.gz"
    sha256 "445c0ef19d8692283f4c3a92052cc0568f5a048f4e546105f58e991d4aea54f5"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.23.2.darwin-arm64.tar.gz"
    sha256 "d87031194fe3e01abdcaf3c7302148ade97a7add6eac3fec26765bcb3207b80f"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.23.2.linux-amd64.tar.gz"
    sha256 "542d3c1705f1c6a1c5a80d5dc62e2e45171af291e755d591c5e6531ef63b454e"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.23.2.linux-arm64.tar.gz"
    sha256 "f626cdd92fc21a88b31c1251f419c17782933a42903db87a174ce74eeecc66a9"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.23.2.linux-armv6l.tar.gz"
    sha256 "e3286bdde186077e65e961cbe18874d42a461e5b9c472c26572b8d4a98d15c40"
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
