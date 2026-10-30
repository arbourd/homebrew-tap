cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.245"
  sha256 arm:   "a413b65998926b0a4654d6b7e0c0f789a5f758ad3a777a3dec60c8de722bbad8",
         intel: "b21b392f15be0c38ee9db7361c1d726db047bc779b9d57718a0e74739cff173f"

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
