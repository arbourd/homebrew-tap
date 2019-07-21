class Trashos < Formula
  desc "Safely move items to macOS trash"
  homepage "https://github.com/arbourd/trashOS"
  url "https://github.com/arbourd/trashOS/archive/v0.1.0.tar.gz"
  sha256 "288c0a225b1fe0b6e692dc60dee7de7b4cbc136935128109b49e4166c46338fa"
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
