class CocoCpp < Formula
  desc "The Compiler Generator Coco/R - C++ version"
  homepage "https://github.com/olesenm/coco-cpp"
  head "https://github.com/olesenm/coco-cpp.git"

  depends_on :xcode => ["6.0", :build]

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    system "#{bin}/coco-cpp"
  end
end
