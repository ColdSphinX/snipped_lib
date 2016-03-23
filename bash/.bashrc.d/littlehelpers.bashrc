if [ -d ${HOME}/.rbenv/bin ]; then
  export PATH="${PATH}:${HOME}/.rbenv/bin"
  eval "$(rbenv init -)"
fi

function devoffile() {
  local noquiet=true
  local dev=''

  if [ "$1" = "-q" ]; then
    noquiet=false
    shift
  fi

  [ -e $1 ] && dev=$(df -P $1 | tail -n 1 | awk '{print $1}' | grep '^/dev')

  if [ $(echo $dev | wc -w) -ne 1 ]; then
    $noquiet && echo "$1 not on local filesystem" >&2
    return 1
  else
    $noquiet && echo $dev
    return 0
  fi
}

function emptythedir() {
  local blank=$(mktemp -d)
  rsync --delete "$blank/" "$1/"
  rm -r $blank
}

if [[ $- =~ i ]]; then

alias config_show="grep -E -v '^(|[[:space:]]*#.*)$'"

function .sysinfo() {
  echo "sh: $(readlink -f /bin/sh)"
  echo "Host: $(hostname -f)"
  echo "Up:  $(uptime)"
  echo "Load: $(cat /proc/loadavg)"
  echo
  echo "Users:"
  echo "---"
  who
  echo
  echo "Logins:"
  echo "---"
  last -5adFixw
  echo
}

function sslchecker() {
  local DOMAIN=$1
  local PORT=$2
  local SERVER=$3
  [ -z $PORT ] && PORT=443
  [ -z $SERVER ] && SERVER=$DOMAIN

  echo "Domain: $DOMAIN"
  echo | openssl s_client -CApath /etc/ssl/certs/ -servername $DOMAIN -connect $SERVER:$PORT | openssl x509 -noout -dates
}

function .ruby-install-system() {
  local force=false
  if [ "$1" = "-f" ]; then
    force=true
    shift
  fi
  local version=$1
  local major=${version%\.[0-9]}

  if [ $(which ruby | wc -w) -ne 0 ] || $force ; then
    apt-get update
    apt-get install -y wget build-essential patch zlib1g-dev libssl-dev libreadline-dev libffi-dev libyaml-dev libffi-dev libpq-dev libyajl-dev libmysqlclient-dev || return 1
    cd /root/ || return 1
    local folder="ruby-${version}"
    local archive="${folder}.tar.gz"
    [ ! -f "$archive" ] && ( wget "http://ftp.ruby-lang.org/pub/ruby/$major/$archive" || return 1 )
    [ -f "$archive" -a ! -d "$folder" ] && ( tar xvf $archive || return 1 )
    cd $folder || return 1
    ./configure || return 1
    make || return 1
    make install || return 1
    gem install mysql pg --no-ri --no-rdoc || return 1
    cd ..
    rm -r $folder $archive
  fi
}

function .ruby-install-user() {
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

fi

