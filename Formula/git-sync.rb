class GitSync < Formula
  desc "Updates your branches"
  homepage "https://github.com/arbourd/git-sync"
  url "https://github.com/arbourd/git-sync/archive/v0.1.1.tar.gz"
  sha256 "486a066db679bc434d3d817a59de95929e25e52c18b25ce457e4b6c52a1ee1be"
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
