class Trash < Formula
  desc "Swiftly move items to the trash in macOS"
  homepage "https://github.com/arbourd/trash"
  url "https://github.com/arbourd/trash/archive/v0.1.0.tar.gz"
  sha256 "a375e81facaefb1c08e4b91ec8fade13bdbf21d90a985ffcbb3b6585aec13cd5"
  head "https://github.com/arbourd/trash.git"

  depends_on :xcode => ["9.0", :build]

  conflicts_with "trash", :because => "both install a `trash` binary"
  conflicts_with "trash-cli", :because => "both install a `trash` binary"

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release", "-Xswiftc",
      "-static-stdlib"
    bin.install ".build/release/TrashCLI" => "trash"
  end

  test do
    system "#{bin}/trash"
  end
end
