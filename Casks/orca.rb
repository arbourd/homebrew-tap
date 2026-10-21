cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.237"
  sha256 arm:   "9a4b7a3277c5ae4d9291b684b22f0f1f00b953feb1173745545abe0b5bf2c274",
         intel: "0e9af60ce51c0d7a6532c751e5ab3cc77c69b24a38938dc256cbf5f93bff09b0"

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
