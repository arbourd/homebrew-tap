class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.24.1"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.24.1.darwin-amd64.tar.gz"
    sha256 "addbfce2056744962e2d7436313ab93486660cf7a2e066d171b9d6f2da7c7abe"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.24.1.darwin-arm64.tar.gz"
    sha256 "295581b5619acc92f5106e5bcb05c51869337eb19742fdfa6c8346c18e78ff88"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.24.1.linux-amd64.tar.gz"
    sha256 "cb2396bae64183cdccf81a9a6df0aea3bce9511fc21469fb89a0c00470088073"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.24.1.linux-arm64.tar.gz"
    sha256 "8df5750ffc0281017fb6070fba450f5d22b600a02081dceef47966ffaf36a3af"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.24.1.linux-armv6l.tar.gz"
    sha256 "6d95f8d7884bfe2364644c837f080f2b585903d0b771eb5b06044e226a4f120a"
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
