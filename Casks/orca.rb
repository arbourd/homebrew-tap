cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.241"
  sha256 arm:   "be5000497b370e9727c2343de50720312b9882d59ec0ba2012c02fbddc8e305e",
         intel: "cde5cb6793b53b19faeb58bb968160571428d023d62bf4c5639b6ab79bc9c90b"

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
