cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.256"
  sha256 arm:   "b3e59f16e30c0e93e9060dfb3ec464ade39aac995758d580a8ec824e50134735",
         intel: "da35cca867b1506d1decd2f84f5d8967813c8c8140473f016b26d4171d12c2bb"

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
