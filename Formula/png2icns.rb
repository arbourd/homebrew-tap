class Png2icns < Formula
  desc "Converts png to icns"
  homepage "https://github.com/bitboss-ca/png2icns"

  url "https://raw.githubusercontent.com/bitboss-ca/png2icns/master/png2icns.sh"
  
  sha256 "91704cb258d7fad432b22dc6ab2c16e8e7bff37bb4d8c767947c3dd6e4877af5"

  def install
    bin.install "png2icns.sh" => "png2icns"
  end
end
