class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.25.2"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.25.2.darwin-amd64.tar.gz"
    sha256 "95493abb01da81638ab5083ff3f97e8f923cb42a64c2e16728e3cf5b0cd3fc5a"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.25.2.darwin-arm64.tar.gz"
    sha256 "d1ade1b480e51b6269b6e65856c602aed047e1f0d32fffef7eebbd7faa8d7687"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.25.2.linux-amd64.tar.gz"
    sha256 "d7fa7f8fbd16263aa2501d681b11f972a5fd8e811f7b10cb9b26d031a3d7454b"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.25.2.linux-arm64.tar.gz"
    sha256 "9aaeb044bf8dbf50ca2fbf0edc5ebc98b90d5bda8c6b2911526df76f61232919"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.25.2.linux-armv6l.tar.gz"
    sha256 "63572d476f02c1f1049e11c42cb2017eb7b241187e219a004e83202a4a17d21e"
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
