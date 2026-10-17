cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.227"
  sha256 arm:   "ed92fc8551a16c004a82f89be94366def5b696813b4e7cab2c6b5089fee6c6ec",
         intel: "a758a44d2c650eb7d7aaea5f6c75a682e74a15ae47354702172cae8e2c3b61c7"

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
