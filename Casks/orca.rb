cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.242"
  sha256 arm:   "d3245e8eefdb8fe76d485cd3750e6ae076aab7fdac57ccb9dccf04dd2076dbc2",
         intel: "3741d6f7f3868f75df41648fadd17f21ed225b24512c55dfb2fe61813417f974"

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
