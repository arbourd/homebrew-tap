class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.26.2"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.26.2.darwin-amd64.tar.gz"
    sha256 "bc3f1500d9968c36d705442d90ba91addf9271665033748b82532682e90a7966"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.26.2.darwin-arm64.tar.gz"
    sha256 "32af1522bf3e3ff3975864780a429cc0b41d190ec7bf90faa661d6d64566e7af"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.26.2.linux-amd64.tar.gz"
    sha256 "990e6b4bbba816dc3ee129eaeaf4b42f17c2800b88a2166c265ac1a200262282"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.26.2.linux-arm64.tar.gz"
    sha256 "c958a1fe1b361391db163a485e21f5f228142d6f8b584f6bef89b26f66dc5b23"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.26.2.linux-armv6l.tar.gz"
    sha256 "0000e45577827b0a8868588c543cbe4232853def1d3d7a344ad6e60ce2b015c8"
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
