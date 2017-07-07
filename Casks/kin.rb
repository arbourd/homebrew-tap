cask 'kin' do
  version '0.2.0'
  sha256 'e303b4c54cced7354e65667173e900a421a15e30d2372f48badca6eb39cacc5d'

  url "https://github.com/arbourd/kin-desktop/releases/download/#{version}/Kin-#{version}-mac.zip"
  appcast 'https://github.com/arbourd/kin-desktop/releases.atom',
          checkpoint: '404011ead5fb07ba693f500bfbf90e8b097a9ac7b6cd1b3a9407a7b9075be2d5'
  name 'Kin'
  homepage 'https://github.com/arbourd/kin-desktop'

  auto_updates true
  depends_on macos: '>= :mountain_lion'

  app 'Kin.app'
end
