cask 'krew' do
  version :latest
  sha256 :no_check

  url 'https://storage.googleapis.com/krew/v0.2.1/krew.tar.gz'
  name 'krew'
  homepage 'https://krew.dev'

  installer script: {
    executable: 'krew-darwin_amd64',
    args:       ['install', 'krew'],
  }

  uninstall delete: ['~/.krew/bin/kubectl-krew', '~/.krew/store/krew']

  zap trash: '~/.krew'
end
