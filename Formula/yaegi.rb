class Yaegi < Formula
  desc "Yet another elegant Go interpreter"
  homepage "https://github.com/containous/yaegi"
  url "https://github.com/containous/yaegi/archive/v0.0.1.tar.gz"
  sha256 "9c55e5b0941d49ecb639d9cb6e9803fe6431dd685c9dfe1d314f7111b6840fcf"
  head "https://github.com/containous/yaegi.git"

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    ENV["GO111MODULE"] = "on"

    dir = buildpath/"src/github.com/containous/yaegi"
    dir.install buildpath.children

    cd dir do
      system "go", "build", "-o", bin/"yaegi", "cmd/yaegi/yaegi.go"
      prefix.install_metafiles
    end
  end

  test do
    assert_match "4", pipe_output("#{bin}/yaegi", "3 + 1", 0)
  end
end
