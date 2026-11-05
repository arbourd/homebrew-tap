cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.250"
  sha256 arm:   "b18dbb3ec5f5a2ea68704834cf76e322f1aae98afbce76d3b667b89dc5b31335",
         intel: "8deee7d078c0d6c93ddc50d179a89f3372ee8ea40c2c4faaf570cbf30fa25e28"

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
