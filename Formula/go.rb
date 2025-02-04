class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.23.6"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.23.6.darwin-amd64.tar.gz"
    sha256 "782da50ce8ec5e98fac2cd3cdc6a1d7130d093294fc310038f651444232a3fb0"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.23.6.darwin-arm64.tar.gz"
    sha256 "5cae2450a1708aeb0333237a155640d5562abaf195defebc4306054565536221"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.23.6.linux-amd64.tar.gz"
    sha256 "9379441ea310de000f33a4dc767bd966e72ab2826270e038e78b2c53c2e7802d"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.23.6.linux-arm64.tar.gz"
    sha256 "561c780e8f4a8955d32bf72e46af0b5ee5e0debe1e4633df9a03781878219202"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.23.6.linux-armv6l.tar.gz"
    sha256 "27a4611010c16b8c4f37ade3aada55bd5781998f02f348b164302fd5eea4eb74"
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
