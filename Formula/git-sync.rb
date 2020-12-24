class GitSync < Formula
  desc "Updates your branches"
  homepage "https://github.com/arbourd/git-sync"
  url "https://github.com/arbourd/git-sync/archive/v0.1.0.tar.gz"
  sha256 "e9c48ce5ddf8ac99a1c241177cdc8570b7fb96441b73bf218aba4925ab73fa8f"
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
