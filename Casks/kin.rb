cask 'kin' do
  version '0.3.0'
  sha256 '30b4edc4b834901e90bd1fea4578b5b8d098d71d2b354d4afa25264d4e08f719'

  url "https://github.com/arbourd/kin-desktop/releases/download/#{version}/Kin-#{version}-mac.zip"
  appcast 'https://github.com/arbourd/kin-desktop/releases.atom',
          checkpoint: '404011ead5fb07ba693f500bfbf90e8b097a9ac7b6cd1b3a9407a7b9075be2d5'
  name 'Kin'
  homepage 'https://github.com/arbourd/kin-desktop'

  auto_updates true
  depends_on macos: '>= :mountain_lion'

  app 'Kin.app'
end
