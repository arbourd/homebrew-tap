cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.248"
  sha256 arm:   "e05a4ffb8e713f80c6d1dc72d920582e6f5adfbcc4f6b138bf19a861452bf7b2",
         intel: "27b956423d04e725e10826b3642fe1340374e2c15b5def8d9a1165c7478970cb"

  url "https://github.com/stablyai/orca/releases/download/v#{version}/orca-macos-#{arch}.dmg"
  name "Orca"
  desc "IDE for running coding agents in parallel"
  homepage "https://github.com/stablyai/orca"

  livecheck do
    url :url
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :monterey

  app "Orca.app"

  zap trash: [
    "~/Library/Application Support/Orca",
    "~/Library/Caches/com.stablyai.orca",
    "~/Library/Caches/com.stablyai.orca.ShipIt",
    "~/Library/Preferences/com.stablyai.orca.plist",
    "~/Library/Saved Application State/com.stablyai.orca.savedState",
  ]
end
