class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.27.2"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.27.2.darwin-amd64.tar.gz"
    sha256 "587b59182488b23aa6e5fc25110405a3e0e5b38ed2f5b2f46ed13c32aee356fe"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.27.2.darwin-arm64.tar.gz"
    sha256 "76812b213b1b2302c978d28fa52fa92d541704b9e7d9d5db8002c50e4018c4c5"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.27.2.linux-amd64.tar.gz"
    sha256 "ecbadb99091a3f46e31f5f934b068b1864eafa7995211b39eaddf76996045fe5"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.27.2.linux-arm64.tar.gz"
    sha256 "94f3e30b8e374bc285e7dadc11e0865726b9bc6e85b841ccceaabc0214c6b7c8"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.27.2.linux-armv6l.tar.gz"
    sha256 "e25a174051d8675f87ac720aedcd25bf89ac652c4b82f26aa47919524725ed95"
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
