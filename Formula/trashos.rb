class Trashos < Formula
  desc "Safely move items to macOS trash"
  homepage "https://github.com/arbourd/trashOS"
  url "https://github.com/arbourd/trashOS/archive/v0.2.0.tar.gz"
  sha256 "384b631880fe91990af415d960dbb18efe95e30aca6369fc72d7c0f7cf1da749"
  head "https://github.com/arbourd/trashOS.git"

  depends_on :xcode => ["10.2", :build]

  conflicts_with "trash", :because => "both install a `trash` binary"
  conflicts_with "trash-cli", :because => "both install a `trash` binary"

  def install
    system "swift", "build", "--disable-sandbox", "--static-swift-stdlib", "-c", "release"
    bin.install ".build/release/TrashCLI" => "trash"
    prefix.install_metafiles
  end

  test do
    assert_match "trash, version #{version}", shell_output("#{bin}/trash --version")
  end
end
