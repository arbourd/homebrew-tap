class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.24.5"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.24.5.darwin-amd64.tar.gz"
    sha256 "2fe5f3866b8fbcd20625d531f81019e574376b8a840b0a096d8a2180308b1672"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.24.5.darwin-arm64.tar.gz"
    sha256 "92d30a678f306c327c544758f2d2fa5515aa60abe9dba4ca35fbf9b8bfc53212"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.24.5.linux-amd64.tar.gz"
    sha256 "10ad9e86233e74c0f6590fe5426895de6bf388964210eac34a6d83f38918ecdc"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.24.5.linux-arm64.tar.gz"
    sha256 "0df02e6aeb3d3c06c95ff201d575907c736d6c62cfa4b6934c11203f1d600ffa"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.24.5.linux-armv6l.tar.gz"
    sha256 "dc043c10cfa60e82687ab2a671d500de1f210042021bc3bca43dfb4fa6bfeca7"
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
