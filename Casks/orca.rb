cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.247"
  sha256 arm:   "3a4ac1dfdd5aa4d83e21dd74d291abe00b9001516dc6bfcde40a8885c0956cdf",
         intel: "3f879a39aecb366f962a080ecfdbd25a850e7a487de0a5ad809f7dc68f5a38af"

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
