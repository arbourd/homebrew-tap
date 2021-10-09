class GitGet < Formula
  desc "Go gets your code"
  homepage "https://github.com/arbourd/git-get"
  url "https://github.com/arbourd/git-get/archive/v0.2.5.tar.gz"
  sha256 "31cca27db98c588683260889d3240ae99ef527237832381b6bdbfcf2670215ac"
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
