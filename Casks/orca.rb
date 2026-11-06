cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.251"
  sha256 arm:   "2588fb3eea34eb0d328b9a5cd3be5ab5b36aafb02622d01308e2cb3535d8e0fe",
         intel: "6d9b6a0ce76a11887cec53183cdf66300f51d41a58a52d5cca279a2d7fc50d65"

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
