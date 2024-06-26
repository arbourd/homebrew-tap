# typed: false
# frozen_string_literal: true

# This file was generated by GoReleaser. DO NOT EDIT.
class GitOpen < Formula
  desc "Opens your Git repository in your browser"
  homepage "https://github.com/arbourd/git-open"
  version "0.2.0"

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/arbourd/git-open/releases/download/v0.2.0/git-open-v0.2.0-darwin-amd64.tar.gz"
      sha256 "dd001c4e42dcfa38d815cc0022998bc9a3ea398e2f40a7b1eb41dce2d231e3d9"

      def install
        bin.install "git-open"
      end
    end
    if Hardware::CPU.arm?
      url "https://github.com/arbourd/git-open/releases/download/v0.2.0/git-open-v0.2.0-darwin-arm64.tar.gz"
      sha256 "0c51d6867d0a483064962f0c755d99ef314443555ec7abe5c85fd29b707cab97"

      def install
        bin.install "git-open"
      end
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/arbourd/git-open/releases/download/v0.2.0/git-open-v0.2.0-linux-amd64.tar.gz"
      sha256 "8068cbe02c27189d3818b27bd6055c857ce265212d9b9b9b522993d8cec70f2c"

      def install
        bin.install "git-open"
      end
    end
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/arbourd/git-open/releases/download/v0.2.0/git-open-v0.2.0-linux-arm64.tar.gz"
      sha256 "1856f2518398c34595491cf3e4c95f95c5b3efc55d114531ec97f81b1d1a0a98"

      def install
        bin.install "git-open"
      end
    end
  end

  conflicts_with "git-open"

  test do
    system "git", "clone", "https://github.com/arbourd/git-open.git"

    cd "git-open" do
      assert_match "Opening https://github.com/arbourd/git-open",
                  shell_output("#{bin}/git-open")
      assert_match "Opening https://github.com/arbourd/git-open/tree/main/LICENSE",
                  shell_output("#{bin}/git-open LICENSE")
      assert_match "Opening https://github.com/arbourd/git-open/commit/71e081deeb92764e1bae203419ac72de1d935d2f",
                  shell_output("#{bin}/git-open 71e081deeb92764e1bae203419ac72de1d935d2f")
    end
  end
end
