cask 'kin' do
  version '0.3.3'
  sha256 '60e70931d8c836b9c98a678d01601af1b17de507be69236cd580ec3d2b24f465'

  url "https://github.com/arbourd/kin-desktop/releases/download/v#{version}/Kin-#{version}-mac.zip"
  appcast 'https://github.com/arbourd/kin-desktop/releases.atom',
          checkpoint: '12cc3ede926a2696fe5debbc894035de15847863fd8711d330f41ca7f2d66b61'
  name 'Kin'
  homepage 'https://github.com/arbourd/kin-desktop'

  auto_updates true
  depends_on macos: '>= :mountain_lion'

  app 'Kin.app'
end
