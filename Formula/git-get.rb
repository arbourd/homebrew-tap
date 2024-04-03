# typed: false
# frozen_string_literal: true

# This file was generated by GoReleaser. DO NOT EDIT.
class GitGet < Formula
  desc "Go gets your code"
  homepage "https://github.com/arbourd/git-get"
  version "0.6.1"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/arbourd/git-get/releases/download/v0.6.1/git-get-v0.6.1-darwin-arm64.tar.gz"
      sha256 "738031ff3f32075d33333646533eed4d7016a2c154b1f9a1ea5a3ff01873b5d5"

      def install
        bin.install "git-get"
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/arbourd/git-get/releases/download/v0.6.1/git-get-v0.6.1-darwin-amd64.tar.gz"
      sha256 "8641dd1e9f8405b69e7829ac589b3aa46225981b5d9c0a4e9229ab89759ac36e"

      def install
        bin.install "git-get"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/arbourd/git-get/releases/download/v0.6.1/git-get-v0.6.1-linux-arm64.tar.gz"
      sha256 "492b60f9940ca49c1e76edf40011201fdd98983ea4ec578de70291ade3a5d988"

      def install
        bin.install "git-get"
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/arbourd/git-get/releases/download/v0.6.1/git-get-v0.6.1-linux-amd64.tar.gz"
      sha256 "773600cb4e04a943433ca7db50d8b6121370364edb826496b5e1c17b3a4dc625"

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
