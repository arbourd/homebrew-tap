cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.246"
  sha256 arm:   "32b91ebe3ccb5304d0c847825a2376df24bc8c6d1e6ab7b40ea4e2e9a620eed5",
         intel: "8bb6a07b96078737e36aefd506b2ce31d2c8fcf964ae6129327e77f8746bed93"

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
