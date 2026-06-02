class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.26.4"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.26.4.darwin-amd64.tar.gz"
    sha256 "05dc9b5f9997744520aaebb3d5deaa7c755371aebbfb7f97c2511a9f3367538d"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.26.4.darwin-arm64.tar.gz"
    sha256 "b62ad2b6d7d2464f12a5bcad7ff47f19d08325773b5efd21610e445a05a9bf53"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.26.4.linux-amd64.tar.gz"
    sha256 "1153d3d50e0ac764b447adfe05c2bcf08e889d42a02e0fe0259bd47f6733ad7f"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.26.4.linux-arm64.tar.gz"
    sha256 "ef758ae7c6cf9267c9c0ef080b8965f453d89ab2d25d9eb22de4405925238768"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.26.4.linux-armv6l.tar.gz"
    sha256 "8db458e995f18a9427a745cefe7a3323962fa2548c4715148963311f300d3b1a"
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
