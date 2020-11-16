class CocoCpp < Formula
  desc "Compiler Generator Coco/R - C++ version"
  homepage "http://www.ssw.uni-linz.ac.at/coco/"
  url "http://www.ssw.uni-linz.ac.at/coco/CPP/CocoSourcesCPP.zip"
  version "20181203"
  sha256 "fa968179d063b3ee6a0047ca70f5948f2f572f82a9194731ad0252ff8c1f7223"

  bottle do
    root_url "https://storage.googleapis.com/homebrew-arbourd-tap"
    cellar :any_skip_relocation
    sha256 "bc36cf059ba62e8ce20cd5e28e03214b51a6ec8b855851aaed8ccdd71131a144" => :mojave
  end

  depends_on xcode: ["6.0", :build]

  def install
    chmod "+x", "./build.sh"
    system "./build.sh"
    bin.install "Coco" => "coco-cpp"
    pkgshare.install "Scanner.frame", "Parser.frame"
  end

  def caveats
    "Frame files have been installed to #{pkgshare}."
  end

  test do
    system "#{bin}/coco-cpp"
  end
end
