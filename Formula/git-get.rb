# typed: false
# frozen_string_literal: true

# This file was generated by GoReleaser. DO NOT EDIT.
class GitGet < Formula
  desc "Go gets your code"
  homepage "https://github.com/arbourd/git-get"
  version "0.5.2"

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/arbourd/git-get/releases/download/v0.5.2/git-get-v0.5.2-darwin-amd64.tar.gz"
      sha256 "14d2a76c76e44264ed35b859b079ffffc9e77be668c3d75d9f1517cdc742015f"

      def install
        bin.install "git-get"
      end
    end
    if Hardware::CPU.arm?
      url "https://github.com/arbourd/git-get/releases/download/v0.5.2/git-get-v0.5.2-darwin-arm64.tar.gz"
      sha256 "902424dca4c5de8fc6528dd0b5c0de3b12f20b2de9a0127a481eecda797e67a2"

      def install
        bin.install "git-get"
      end
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/arbourd/git-get/releases/download/v0.5.2/git-get-v0.5.2-linux-amd64.tar.gz"
      sha256 "9c27527f6656fe8a5072164ca79cbb577b8dacef644e17e76ba3846eb9add38c"

      def install
        bin.install "git-get"
      end
    end
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/arbourd/git-get/releases/download/v0.5.2/git-get-v0.5.2-linux-arm64.tar.gz"
      sha256 "f2cb300a0374ec933ad083d2495dd023b784b88cbba4fd3e8980749a5539267e"

      def install
        bin.install "git-get"
      end
    end
  end

  conflicts_with "git-extras"

  test do
    repo = "github.com/arbourd/git-get"
    assert_match "#{testpath}/src/#{repo}", shell_output("#{bin}/git-get #{repo}")

    cd "#{testpath}/src/#{repo}" do
      assert_match "https://#{repo}", shell_output("git remote -v")
    end
  end
end
