cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.239"
  sha256 arm:   "5a870f3be444abcef4c14fd53a0cb398744e7a4f4aa105376ee810d195e33780",
         intel: "e399f97a44b4e09626d8fb20020380b472945025cc1f71e1ac44559f0b5ae239"

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
