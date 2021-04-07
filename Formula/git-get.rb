class GitGet < Formula
  desc "Go gets your code"
  homepage "https://github.com/arbourd/git-get"
  url "https://github.com/arbourd/git-get/archive/v0.2.4.tar.gz"
  sha256 "152b748923cacd23d5b094517619c8bfa8092ba5f96f430dd83e27f936927dc5"
  head "https://github.com/arbourd/git-get.git"

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
    assert_match "#{testpath}/src/github.com/arbourd/git-get",
                 shell_output("#{bin}/git-get github.com/arbourd/git-get")
  end
end
