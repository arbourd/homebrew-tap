class GitSync < Formula
  desc "Updates your branches"
  homepage "https://github.com/arbourd/git-sync"
  url "https://github.com/arbourd/git-sync/archive/v0.1.2.tar.gz"
  sha256 "8ea7a0fd1e3f5959f01e81773277d376e0bb88da8a57acf139a43696f5b00ee2"
  head "https://github.com/arbourd/git-sync.git"

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    ENV["GO111MODULE"] = "on"

    dir = buildpath/"src/github.com/arbourd/git-sync"
    dir.install buildpath.children

    cd dir do
      system "go", "build", "-o", bin/"git-sync"
      prefix.install_metafiles
    end
  end
end
