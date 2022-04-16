class Ockam < Formula
  desc "End-to-end encryption and mutual authentication for distributed applications"
  homepage "https://www.ockam.io/"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ockam-network/ockam/releases/download/ockam_cli_preview_v0.12.0/ockam.aarch64-apple-darwin"
      sha256 "7b0b7822bbc6655dcb8cacf559f00a6535048b5e972b9520046fb1ab70d42900"

      def install
        mv "ockam.aarch64-apple-darwin", "ockam"
        bin.install "ockam"
      end
    end

    if Hardware::CPU.intel?
      url "https://github.com/ockam-network/ockam/releases/download/ockam_cli_preview_v0.12.0/ockam.x86_64-apple-darwin"
      sha256 "4188cbcf1c3be55b6c233e04522ff8b41e402bc38ce74d78b53429e3e7e89707"

      def install
        mv "ockam.x86_64-apple-darwin", "ockam"
        bin.install "ockam"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ockam-network/ockam/releases/download/ockam_cli_preview_v0.12.0/ockam.aarch64-unknown-linux-gnu"
      sha256 "11536714d24a0d3d562cc89f9b37e0b80de2ba5972399ffcaa6f7d8bfa2b1574"

      def install
        mv "ockam.x86_64-unknown-linux-gnu", "ockam"
        bin.install "ockam"
      end
    end

    if Hardware::CPU.intel?
      url "https://github.com/ockam-network/ockam/releases/download/ockam_cli_preview_v0.12.0/ockam.x86_64-unknown-linux-gnu"
      sha256 "d5324c288ceec6523eb0e4d06ad483073f22dbbf8d7118936bcb48642699b240"

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
