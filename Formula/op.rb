class Op < Formula
  desc "1Password CLI"
  homepage "https://app-updates.agilebits.com/product_history/CLI"

  url "https://cache.agilebits.com/dist/1P/op/pkg/v0.5.7/op_darwin_amd64_v0.5.7.zip"
  sha256 "f382de2e5682c8f6a935123a9401cb77db6680233c80c5e9118cfa70b3f1959a"

  def install
    bin.install "op"
  end

  test do
    system "#{bin}/op"
  end
end
