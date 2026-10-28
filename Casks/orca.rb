cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.243"
  sha256 arm:   "b0d030a7f3ba0849677e4efad92c0af63ef268332c24b176df9ddd7a1f5a6551",
         intel: "ac094261cb344392d6a2536c901c312b85013edd986cd9b6eb62554dbd46cfee"

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
