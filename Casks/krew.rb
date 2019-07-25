cask 'krew' do
  version :latest
  sha256 :no_check

  # storage.googleapis.com was verified as official when first introduced to the cask
  url 'https://storage.googleapis.com/krew/v0.2.1/krew.tar.gz'
  name 'krew'
  homepage 'https://krew.dev/'

  installer script: {
                      executable: 'krew-darwin_amd64',
                      args:       ['install', 'krew'],
                    }

  uninstall delete: ['~/.krew/bin/kubectl-krew', '~/.krew/store/krew']

  zap trash: '~/.krew'
end
