class Png2icns < Formula
  desc "Converts png to icns"
  homepage "https://github.com/bitboss-ca/png2icns"
  url "https://github.com/bitboss-ca/png2icns/archive/v0.1.tar.gz"
  sha256 "adb9726483770dac9f9945e791223e1977aeb008481ea5dd80cdaaedd1bb3714"
  head "https://github.com/bitboss-ca/png2icns.git"

  bottle :unneeded

  def install
    bin.install "png2icns.sh" => "png2icns"
    pkgshare.install "SampleImage.png"
    prefix.install_metafiles
  end

  test do
    system "#{bin}/png2icns", "#{pkgshare}/SampleImage.png"
    assert_predicate testpath/"SampleImage.icns", :exist?
  end
end
