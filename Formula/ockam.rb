class Ockam < Formula
  desc "End-to-end encryption and mutual authentication for distributed applications"
  homepage "https://www.ockam.io/"
  version "0.1.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ockam-network/ockam/releases/download/ockam_cli_preview_v0.0.1/ockam.aarch64-apple-darwin"
      sha256 "9be59381b949253d57c7be4b99fddfc92d8226ed06a248a6cc751793b0c51136"

      def install
        mv "ockam.aarch64-apple-darwin", "ockam"
        bin.install "ockam"
      end
    end

    if Hardware::CPU.intel?
      url "https://github.com/ockam-network/ockam/releases/download/ockam_cli_preview_v0.0.1/ockam.x86_64-apple-darwin"
      sha256 "2eb7749fcc80d977b784e249d54ba4c3e0bb9a31475d7273ffc82c7c2f5a5a27"

      def install
        mv "ockam.x86_64-apple-darwin", "ockam"
        bin.install "ockam"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ockam-network/ockam/releases/download/ockam_cli_preview_v0.0.1/ockam.x86_64-unknown-linux-gnu"
      sha256 "fced37593eb3e7dacaba2cec82106a8aa5aaac8fb1a67a2dcf9d9712859c4a30"

      def install
        mv "ockam.x86_64-unknown-linux-gnu", "ockam"
        bin.install "ockam"
      end
    end

    if Hardware::CPU.intel?
      url "https://github.com/ockam-network/ockam/releases/download/ockam_cli_preview_v0.0.1/ockam.aarch64-unknown-linux-gnu"
      sha256 "7ac7b396a691e588c5fb57687759e6c4db84a2a3bbebb0765f4b38e5b1c5b00e"

      def install
        mv "ockam.aarch64-unknown-linux-gnu", "ockam"
        bin.install "ockam"
      end
    end
  end

  test do
    system "ockam", "--version"
  end
end
