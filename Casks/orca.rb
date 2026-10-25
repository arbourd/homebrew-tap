cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.240"
  sha256 arm:   "6020a633e2f3775d77395f5a9703f9a11d31fbf0fe0afeab8dbed39e140fbe90",
         intel: "24ae4ded325e058edde6819bfe80f80f96fd478316c8eec8ee6307df77d3221f"

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
