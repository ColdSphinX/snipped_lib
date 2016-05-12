[[ $- != *i* ]] && return 0

function .install-ruby-user() {
  local force=false
  if [ "$1" = "-f" ]; then
    force=true
    shift
  fi
  local version=$1
  local major=${version%\.[0-9]}
  local rbehome="${HOME}/.rbenv"

  echo "ensure that the following packages are installed:" >&2
  echo "apt-get install -y wget build-essential patch zlib1g-dev libssl-dev libreadline-dev libffi-dev libyaml-dev libffi-dev libpq-dev libyajl-dev libmysqlclient-dev git" >&2
  read -n1 -r -p "Press <enter> to continue..." key
  if [ -d "${HOME}/.rbenv" ]; then
    rbenv install $version
  else
    git clone https://github.com/rbenv/rbenv.git "$rbehome"
    for plugin in ruby-build rbenv-default-gems rbenv-each rbenv-vars
    do
      git clone https://github.com/rbenv/${plugin}.git "$rbehome/plugins/$plugin"
    done
    cat $rbehome/default-gems <<DEFGEMS
bundler
capistrano ~>2.0
DEFGEMS
    export PATH="$PATH:$rbehome/bin"
    eval "$(rbenv init -)"
    rbenv install $version
    [ ! -f "$rbehome/version" ] && rbenv global $version
  fi
}

function .install-neovim-user() {
  cd ~/tmp/ || return 1
  [[ -d neovim ]] && rm -rf neovim
  git clone https://github.com/neovim/neovim neovim || return 1
  cd neovim || return 1
  PREFIX=$HOME/nvim make &>/dev/null
  make clean &>/dev/null
  cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=$HOME/nvim -DENABLE_JEMALLOC=ON || return 1
  make || return 1
  make install
  unset PREFIX
}

function .install-neovim-system() {
  cd ~/tmp/ || return 1
  [[ -d neovim ]] && rm -rf neovim
  git clone https://github.com/neovim/neovim neovim || return 1
  cd neovim || return 1
  PREFIX=/usr/local make &>/dev/null
  make clean &>/dev/null
  cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=/usr/local -DENABLE_JEMALLOC=ON || return 1
  make || return 1
  make install
  unset PREFIX
}

function hostmux_install() {
  git clone -b stable https://github.com/ColdSphinX/hostmux.git $HOME/hostmux
  type -a tmux &>/dev/null || echo "please install tmux" >&2
}

# vi: syntax=sh ts=2

