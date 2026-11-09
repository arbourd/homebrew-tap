cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.255"
  sha256 arm:   "7c4df2e2429c674154f0fcc61ba8e1f9efb1b4e8d3b92983d7d1494293c2421a",
         intel: "667c11b7dbe4da1e91fbea60d5c7921a5f30fb67c6e9f88f0a5ed48ced3c329d"

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
  depends_on macos: :ventura

  app "Orca.app"

  zap trash: [
    "~/Library/Application Support/Orca",
    "~/Library/Caches/com.stablyai.orca",
    "~/Library/Caches/com.stablyai.orca.ShipIt",
    "~/Library/Preferences/com.stablyai.orca.plist",
    "~/Library/Saved Application State/com.stablyai.orca.savedState",
  ]
end
