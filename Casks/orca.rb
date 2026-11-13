cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.258"
  sha256 arm:   "101a3452097ec303ef43b5e5ff06a86dfa8c534e17154c85be0a9297eba55199",
         intel: "e28a685c42a62e0d9b35f3be3b41bde3db654342521d7194490b5ae37931cb3d"

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
