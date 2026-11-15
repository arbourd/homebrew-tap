cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.259"
  sha256 arm:   "4118e9e4ec0e78349570f5e35bb0f1a6a6f8b09d7e1122348b9536805d436fb1",
         intel: "6028c5c48608c88f249955e00b567c90c1141e58291ec2fc88e0746addcb6bc9"

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
