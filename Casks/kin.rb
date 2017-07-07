cask 'kin' do
  version '0.1.0'
  sha256 '676ef9f1fd84404d205785767dc45c0e9b3d7324b906a3292573182e869ba33a'

  url "https://github.com/arbourd/kin-desktop/releases/download/#{version}/Kin-#{version}-mac.zip"
  appcast 'https://github.com/arbourd/kin-desktop/releases.atom',
          checkpoint: '404011ead5fb07ba693f500bfbf90e8b097a9ac7b6cd1b3a9407a7b9075be2d5'
  name 'Kin'
  homepage 'https://github.com/arbourd/kin-desktop'

  auto_updates true
  depends_on macos: '>= :mountain_lion'

  app 'Kin.app'
end
