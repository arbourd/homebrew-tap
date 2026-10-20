class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.27.3"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.27.3.darwin-amd64.tar.gz"
    sha256 "b6f8e931e4ab497fcde6da8ae4499a58f9d258e55c8a80824a516eae5950a750"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.27.3.darwin-arm64.tar.gz"
    sha256 "dd3908cf20959d798c1e06ebe5b72213f0505ce01373b40ce3110975a6cd99c2"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.27.3.linux-amd64.tar.gz"
    sha256 "65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.27.3.linux-arm64.tar.gz"
    sha256 "a06e99309dbcbdca1a8ccd2282c3ee146e55930886e26b4f1193269587165f49"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.27.3.linux-armv6l.tar.gz"
    sha256 "d6f4e11dd7157030d7ac11c51c8f73201a2db932d593c3106b1da11cc32bfdf8"
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
