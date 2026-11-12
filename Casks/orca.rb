cask "orca" do
  arch arm: "arm64", intel: "x64"

  version "1.4.257"
  sha256 arm:   "496772b8967677e9839f0f8f438e4d38db0b17f36faecf47d1f5b94187b00594",
         intel: "ec12f69e56b33507d9a503c412495efae9ad06063ff990cf62ee99b1ff752f2f"

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
