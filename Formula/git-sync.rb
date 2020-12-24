class GitSync < Formula
    desc "Updates your branches"
    homepage "https://github.com/arbourd/git-sync"
    url "https://github.com/arbourd/git-sync/archive/v0.0.0.tar.gz"
    sha256 "892c39068d89c5029e08d8f8ebfbe1a268552bcafd6ac189786505cd231bd4cb"
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
