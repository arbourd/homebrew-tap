class GitGet < Formula
  desc "Go gets your code"
  homepage "https://github.com/arbourd/git-get"
  url "https://github.com/arbourd/git-get/archive/v0.1.1.tar.gz"
  sha256 "1b2049fe81142bd258a00eaed35ed7de9208f45c3059a61f6266c420e969c002"
  head "https://github.com/arbourd/git-get.git"

  bottle do
    root_url "https://storage.googleapis.com/homebrew-arbourd-tap"
    cellar :any_skip_relocation
    sha256 "b4854189915dc4246a6401177ace8d9b87dac390b707cb2b5f903b9683354748" => :mojave
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    ENV["GO111MODULE"] = "on"

    dir = buildpath/"src/github.com/arbourd/git-get"
    dir.install buildpath.children

    cd dir do
      system "go", "build", "-o", bin/"git-get"
      prefix.install_metafiles
    end
  end

  test do
    assert_match "#{testpath}/src/github.com/arbourd/language-systemd",
                 shell_output("#{bin}/git-get github.com/arbourd/language-systemd")
  end
end
