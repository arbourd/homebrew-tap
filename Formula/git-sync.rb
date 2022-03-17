# typed: false
# frozen_string_literal: true

# This file was generated by GoReleaser. DO NOT EDIT.
class GitSync < Formula
  desc "Updates your branches"
  homepage "https://github.com/arbourd/git-sync"
  version "0.2.2"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/arbourd/git-sync/releases/download/v0.2.2/git-sync-v0.2.2-darwin-arm64.tar.gz"
      sha256 "1936792a970ce8c48fddd1ec898db8ffd1578fd19be3e6e257bb4fb4d0aa2598"

      def install
        bin.install "git-sync"
      end
    end
    if Hardware::CPU.intel?
      url "https://github.com/arbourd/git-sync/releases/download/v0.2.2/git-sync-v0.2.2-darwin-amd64.tar.gz"
      sha256 "0d5370ca8bde63a5b437dd2280dde1f4fb8e2b0c5f61e3dbd86d19da65bd5036"

      def install
        bin.install "git-sync"
      end
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/arbourd/git-sync/releases/download/v0.2.2/git-sync-v0.2.2-linux-amd64.tar.gz"
      sha256 "01c594ee741d32cdd390632f995b6837fc750073eb6d67e77e94644943dc9d23"

      def install
        bin.install "git-sync"
      end
    end
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/arbourd/git-sync/releases/download/v0.2.2/git-sync-v0.2.2-linux-arm64.tar.gz"
      sha256 "6ed2dcd2838fef68efc9bddf6d37c751375ff5eae7908ca35c9cee908e9c9bb0"

      def install
        bin.install "git-sync"
      end
    end
  end
end
