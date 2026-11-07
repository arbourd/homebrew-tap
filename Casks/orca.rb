cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.253"
  sha256 arm:   "26794e3138006e063506e5fbbc0597cfd9df2d060bd7bc1e2c66bf89896c1900",
         intel: "e93bfc5a8288deb5662a47ed1d82a6c62a87e65f912f0fbed0a2d25012c887eb"

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
