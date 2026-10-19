cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.230"
  sha256 arm:   "f8de9f991fae9c7266c937ccf3558d8ff97d97487270fd5e8f332a73b956a6e4",
         intel: "f9d843ca06b39b11546e771f6501afee7f7ef0f982e86ddca485a27957621cb3"

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
