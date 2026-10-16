cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.224"
  sha256 arm:   "7382f5e0d1a7f5c8253c17c975dc781710fec67fb8cfbaf9d11c03bfc60baae1",
         intel: "55635c5c7e730685ba736acc778265e02a5c49c47896a2fb7f0836de85dfb3f6"

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
