class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.23.5"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.23.5.darwin-amd64.tar.gz"
    sha256 "d8b310b0b6bd6a630307579165cfac8a37571483c7d6804a10dd73bbefb0827f"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.23.5.darwin-arm64.tar.gz"
    sha256 "047bfce4fbd0da6426bd30cd19716b35a466b1c15a45525ce65b9824acb33285"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.23.5.linux-amd64.tar.gz"
    sha256 "cbcad4a6482107c7c7926df1608106c189417163428200ce357695cc7e01d091"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.23.5.linux-arm64.tar.gz"
    sha256 "47c84d332123883653b70da2db7dd57d2a865921ba4724efcdf56b5da7021db0"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.23.5.linux-armv6l.tar.gz"
    sha256 "04e0b5cf5c216f0aa1bf8204d49312ad0845800ab0702dfe4357c0b1241027a3"
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
