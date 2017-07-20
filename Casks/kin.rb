cask 'kin' do
  version '0.3.1'
  sha256 '4b0555e9a16b2169c4400a1efa4f372b63a41a2ee0bd0a0391c635be0a5070f7'

  url "https://github.com/arbourd/kin-desktop/releases/download/#{version}/Kin-#{version}-mac.zip"
  appcast 'https://github.com/arbourd/kin-desktop/releases.atom',
          checkpoint: '404011ead5fb07ba693f500bfbf90e8b097a9ac7b6cd1b3a9407a7b9075be2d5'
  name 'Kin'
  homepage 'https://github.com/arbourd/kin-desktop'

  auto_updates true
  depends_on macos: '>= :mountain_lion'

  app 'Kin.app'
end
