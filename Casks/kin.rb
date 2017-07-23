cask 'kin' do
  version '0.3.2'
  sha256 'fca7bf759a0f8643142323e606ef836b2189723d50cfeaa678e968e74b0cc644'

  url "https://github.com/arbourd/kin-desktop/releases/download/v#{version}/Kin-#{version}-mac.zip"
  appcast 'https://github.com/arbourd/kin-desktop/releases.atom',
          checkpoint: '05d6158af73482b707d08870a03e537fb34fc56e11e1c680e008370e0051da12'
  name 'Kin'
  homepage 'https://github.com/arbourd/kin-desktop'

  auto_updates true
  depends_on macos: '>= :mountain_lion'

  app 'Kin.app'
end
