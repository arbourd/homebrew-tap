class GitGet < Formula
  desc "Go gets your code"
  homepage "https://github.com/arbourd/git-get"
  url "https://github.com/arbourd/git-get/archive/v0.2.3.tar.gz"
  sha256 "904a1a9c405625c5a186f6e1769b9360e2b2f02e86b64fa1bc73dfaa262f9ca2"
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
