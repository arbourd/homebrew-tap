class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  version "1.22.0"

  if OS.mac?
    url "https://go.dev/dl/go1.22.0.darwin-amd64.tar.gz"
    sha256 "ebca81df938d2d1047cc992be6c6c759543cf309d401b86af38a6aed3d4090f4"
  end

  if OS.mac? && Hardware::CPU.arm?
    url "https://go.dev/dl/go1.22.0.darwin-arm64.tar.gz"
    sha256 "bf8e388b09134164717cd52d3285a4ab3b68691b80515212da0e9f56f518fb1e"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://go.dev/dl/go1.22.0.linux-amd64.tar.gz"
    sha256 "f6c8a87aa03b92c4b0bf3d558e28ea03006eb29db78917daec5cfb6ec1046265"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.22.0.linux-arm64.tar.gz"
    sha256 "6a63fef0e050146f275bf02a0896badfe77c11b6f05499bb647e7bd613a45a10"
  end

  if OS.linux? && Hardware::CPU.arm? && !Hardware::CPU.is_64_bit?
    url "https://go.dev/dl/go1.22.0.linux-armv6l.tar.gz"
    sha256 "0525f92f79df7ed5877147bce7b955f159f3962711b69faac66bc7121d36dcc4"
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

    ENV["GOOS"] = "freebsd"
    ENV["GOARCH"] = "amd64"
    system bin/"go", "build", "hello.go"
  end
end
