# typed: false
# frozen_string_literal: true

# This file was generated by GoReleaser. DO NOT EDIT.
class Trash < Formula
  desc "Safely move items to macOS trash"
  homepage "https://github.com/arbourd/trashOS"
  version "0.3.4"
  depends_on :macos

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/arbourd/trashOS/releases/download/v0.3.4/trash-v0.3.4-darwin-arm64.tar.gz"
      sha256 "37cab8a69e497f9bd9176513e0f8a4bdcf38a33b78d025c4996efa0af4dc37b5"

      def install
        bin.install "trash"
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/arbourd/trashOS/releases/download/v0.3.4/trash-v0.3.4-darwin-amd64.tar.gz"
      sha256 "252dfeb7bdf3980f2a4388b5833a86083a9907cdde7138d8ffa521bf2205ffa8"

      def install
        bin.install "trash"
      end
    end
  end

  conflicts_with "trash"
  conflicts_with "trash-cli"

  test do
    assert_match "trash, version #{version}", shell_output("#{bin}/trash --version")
  end
end
