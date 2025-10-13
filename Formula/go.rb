class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.25.3"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.25.3.darwin-amd64.tar.gz"
    sha256 "1641050b422b80dfd6299f8aa7eb8798d1cd23eac7e79f445728926e881b7bcd"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.25.3.darwin-arm64.tar.gz"
    sha256 "7c083e3d2c00debfeb2f77d9a4c00a1aac97113b89b9ccc42a90487af3437382"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.25.3.linux-amd64.tar.gz"
    sha256 "0335f314b6e7bfe08c3d0cfaa7c19db961b7b99fb20be62b0a826c992ad14e0f"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.25.3.linux-arm64.tar.gz"
    sha256 "1d42ebc84999b5e2069f5e31b67d6fc5d67308adad3e178d5a2ee2c9ff2001f5"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.25.3.linux-armv6l.tar.gz"
    sha256 "3992bd28316484be0af36494124588581aa27e0659a436d607b11d534045bc1f"
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
