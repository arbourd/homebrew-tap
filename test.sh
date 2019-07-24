#!/usr/bin/env bash

set -exo pipefail
export HOMEBREW_NO_INSTALL_CLEANUP=1

if [[ "$1" = "brew" ]]; then
  brew audit --strict --online ./Formula/*.rb
  brew install ./Formula/*.rb
  brew test ./Formula/*.rb
elif [[ "$1" = "cask" ]]; then
  brew cask audit ./Casks/*.rb
  brew cask install ./Casks/*.rb
  brew cask uninstall ./Casks/*.rb
fi
