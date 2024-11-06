class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.23.3"

  if OS.mac? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.23.3.darwin-amd64.tar.gz"
    sha256 "c7e024d5c0bc81845070f23598caf02f05b8ae88fd4ad2cd3e236ddbea833ad2"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.23.3.darwin-arm64.tar.gz"
    sha256 "31e119fe9bde6e105407a32558d5b5fa6ca11e2bd17f8b7b2f8a06aba16a0632"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.23.3.linux-amd64.tar.gz"
    sha256 "a0afb9744c00648bafb1b90b4aba5bdb86f424f02f9275399ce0c20b93a2c3a8"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.23.3.linux-arm64.tar.gz"
    sha256 "1f7cbd7f668ea32a107ecd41b6488aaee1f5d77a66efd885b175494439d4e1ce"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.23.3.linux-armv6l.tar.gz"
    sha256 "5f0332754beffc65af65a7b2da76e9dd997567d0d81b6f4f71d3588dc7b4cb00"
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
