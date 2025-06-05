class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.24.4"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.24.4.darwin-amd64.tar.gz"
    sha256 "69bef555e114b4a2252452b6e7049afc31fbdf2d39790b669165e89525cd3f5c"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.24.4.darwin-arm64.tar.gz"
    sha256 "27973684b515eaf461065054e6b572d9390c05e69ba4a423076c160165336470"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.24.4.linux-amd64.tar.gz"
    sha256 "77e5da33bb72aeaef1ba4418b6fe511bc4d041873cbf82e5aa6318740df98717"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.24.4.linux-arm64.tar.gz"
    sha256 "d5501ee5aca0f258d5fe9bfaed401958445014495dc115f202d43d5210b45241"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.24.4.linux-armv6l.tar.gz"
    sha256 "6a554e32301cecae3162677e66d4264b81b3b1a89592dd1b7b5c552c7a49fe37"
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
