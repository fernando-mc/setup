#!/usr/bin/env bash

brews=(
  zsh
  bash
  git
  httpie
  node
  postgresql
  python
  python3
  scala
  tree
  trash
  wget
)

casks=(
  atom
  dropbox
  firefox
  google-chrome
  qlmarkdown
  slack
)

pips=(
  virtualenv
)

npms=(
  mysql
)

git_configs=(
  "user.name Fernando Medina Corey"
  "user.email fmcorey@gmail.com"
)

apms=(
  markdown-writer
  atom-beautify
)

fonts=(
  font-source-code-pro
)

######################################## End of app list ########################################
set +e
set -x

if test ! $(which brew); then
  echo "Installing Xcode ..."
  xcode-select --install

  echo "Installing Homebrew ..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Updating Homebrew ..."
  brew update
  brew upgrade
fi
brew doctor
brew tap homebrew/dupes

fails=()

function print_red {
  red='\x1B[0;31m'
  NC='\x1B[0m' # no color
  echo -e "${red}$1${NC}"
}

# Sets up wrapper install script
# for multiple installers (pip, brew, npm, etc.)
function install {
  cmd=$1
  shift
  for pkg in $@;
  do
    exec="$cmd $pkg"
    echo "Executing: $exec"
    if $exec ; then
      echo "Installed $pkg"
    else
      fails+=($pkg)
      print_red "Failed to execute: $exec"
    fi
  done
}

echo "Installing ruby ..."
brew install ruby-install chruby
ruby-install ruby
chruby ruby-2.3.0
ruby -v

echo "Installing Java ..."
brew cask install java

echo "Installing packages ..."
brew info ${brews[@]}
install 'brew install' ${brews[@]}

echo "Installing software ..."
brew cask info ${casks[@]}
install 'brew cask install --appdir=/Applications' ${casks[@]}

echo "Installing secondary packages ..."
install 'pip install --upgrade' ${pips[@]}
install 'npm install --global' ${npms[@]}
install 'apm install' ${apms[@]}
install 'brew cask install' ${fonts[@]}

echo "Upgrading bash ..."
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
cd; curl -#L https://github.com/barryclark/bashstrap/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,screenshot.png}
source ~/.bash_profile

echo "Setting git defaults ..."
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

echo "Setting up go ..."
mkdir -p /usr/libs/go
echo "export GOPATH=/usr/libs/go" >> ~/.bashrc
echo "export PATH=$PATH:$GOPATH/bin" >> ~/.bashrc

echo "Upgrading ..."
pip install --upgrade setuptools
pip install --upgrade pip

echo "Cleaning up ..."
brew cleanup
brew cask cleanup
brew linkapps

for fail in ${fails[@]}
do
  echo "Failed to install: $fail"
done

echo "Done!"
