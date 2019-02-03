class Op < Formula
  desc "1Password CLI"
  homepage "https://app-updates.agilebits.com/product_history/CLI"

  url "https://cache.agilebits.com/dist/1P/op/pkg/v0.5.5/op_darwin_amd64_v0.5.5.zip"
  sha256 "e4ea329debcf991434d90728fa3cba531bce5449a08883d3530dfeb796fc3a3b"

  def install
    bin.install "op"
  end
end
