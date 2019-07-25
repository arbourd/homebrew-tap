.EXPORT_ALL_VARIABLES:
HOMEBREW_NO_ANALYTICS = 1
HOMEBREW_NO_AUTO_UPDATE = 1
HOMEBREW_NO_INSTALL_CLEANUP = 1

test: test-brew test-cask

test-brew:
	brew audit --strict ./Formula/*.rb
	brew install ./Formula/*.rb
	brew test ./Formula/*.rb

test-cask:
	brew cask style --fix ./Casks/*.rb
	brew cask audit ./Casks/*.rb
	brew cask install ./Casks/*.rb
	brew cask uninstall ./Casks/*.rb

.PHONY: test test-brew test-cask
