cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.229"
  sha256 arm:   "3f007ef5e2248fe361b6487454e00f3907aa9537a249fcfe5c86e5ed1ff94398",
         intel: "3f44d844e5d9fe64db00dfce545062d6620bf87156de1227b6bb58c9301aba52"

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
