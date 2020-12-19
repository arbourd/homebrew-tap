class Trashos < Formula
  desc "Safely move items to macOS trash"
  homepage "https://github.com/arbourd/trashOS"
  url "https://github.com/arbourd/trashOS/archive/v0.3.1.tar.gz"
  sha256 "48ea49f22c63734d3eb3594f7063f589da59403bd3b2c4555a5e8700c9a9c818"
  head "https://github.com/arbourd/trashOS.git"

  bottle do
    root_url "https://storage.googleapis.com/homebrew-arbourd-tap"
    cellar :any_skip_relocation
    sha256 "1a9b99f0c5d6f21c954fb2efe4b5d51a770db00bbb77ebaa17c41a1bb68e83f6" => :mojave
  end

  depends_on xcode: ["11.4", :build]

  conflicts_with "trash", because: "both install a `trash` binary"
  conflicts_with "trash-cli", because: "both install a `trash` binary"

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"
    bin.install ".build/release/TrashCLI" => "trash"
    prefix.install_metafiles
  end

  test do
    assert_match "trash, version #{version}", shell_output("#{bin}/trash --version")
  end
end
