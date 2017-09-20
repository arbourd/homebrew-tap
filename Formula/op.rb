class Op < Formula
  desc "1Password CLI"
  homepage "https://app-updates.agilebits.com/product_history/CLI"

  url "https://cache.agilebits.com/dist/1P/op/pkg/v0.1.1/op_darwin_amd64_v0.1.1.zip"
  sha256 "95eb4cfd62a5bf1eab99d4acb24ab9229fc4dfb16a931dd7f9628f88b54c1fc7"

  def install
    bin.install "op"
  end
end
