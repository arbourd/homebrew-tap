class Trashos < Formula
  desc "Safely move items to macOS trash"
  homepage "https://github.com/arbourd/trashOS"
  url "https://github.com/arbourd/trashOS/archive/v0.3.0.tar.gz"
  sha256 "987c3800135ab0dcd41c252242ef0d5a6ee9c3c55cdf523a043634283c8d1257"
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
