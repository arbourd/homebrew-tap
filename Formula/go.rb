class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.25.7"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.25.7.darwin-amd64.tar.gz"
    sha256 "bf5050a2152f4053837b886e8d9640c829dbacbc3370f913351eb0904cb706f5"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.25.7.darwin-arm64.tar.gz"
    sha256 "ff18369ffad05c57d5bed888b660b31385f3c913670a83ef557cdfd98ea9ae1b"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.25.7.linux-amd64.tar.gz"
    sha256 "12e6d6a191091ae27dc31f6efc630e3a3b8ba409baf3573d955b196fdf086005"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.25.7.linux-arm64.tar.gz"
    sha256 "ba611a53534135a81067240eff9508cd7e256c560edd5d8c2fef54f083c07129"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.25.7.linux-armv6l.tar.gz"
    sha256 "1ba07e0eb86b839e72467f4b5c7a5597d07f30bcf5563c951410454f7cda5266"
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
