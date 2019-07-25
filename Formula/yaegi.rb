class Yaegi < Formula
  desc "Yet another elegant Go interpreter"
  homepage "https://github.com/containous/yaegi"
  url "https://github.com/containous/yaegi/archive/v0.0.3.tar.gz"
  sha256 "4473f490d7c79c30e93ccdc756cdd08d67c0cfba0c42e7d828e77c4b5072403b"
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
