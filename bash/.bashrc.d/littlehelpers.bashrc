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

function _strip() {
  sed 's/[[:space:]]//g'
}

function _bin() {
  type -a $1 | grep "is /" | sed 's_^.* \(/.*\)$_\1_'
}

function _has_bin() {
  type -a $1 2>/dev/null | grep -q "is /"
}

function calc() {
  if _has_bin calc ; then
    $(_bin calc) "$*" | _strip
  else
    echo "$*" | bc -l
  fi
}

if [[ $- =~ i ]]; then

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias lr='ls -lachtr'

alias config_show="grep -E -v '^(|[[:space:]]*#.*)$'"
alias ,="ssh -l root"
alias _='mosh --ssh="ssh -X -l root"'
alias apg="/usr/bin/apg -a 1 -n 10 -m 12 -x 12"

alias hist='history | grep'
alias psg='ps -Alf | grep'

# failsafe :D
alias :q=' exit'
alias :Q=' exit'
alias :x=' exit'
alias cd..='cd ..'

alias ,bashrc=". $HOME/.bashrc"
alias ,bashrced="vim $HOME/.bashrc"

function cl() {
  dir=$1
  [[ -z "$dir" ]] && dir=$HOME
  if [[ -d "$dir" ]]; then
    cd "$dir"
    ls
  else
    echo "bash: cl: '$dir': Directory not found" >&2
    return 1
  fi
}

function mcd() {
  mkdir -p "$1" && cd "$1"
}

function extract() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)  tar xjf $1      ;;
      *.tar.gz)   tar xzf $1      ;;
      *.bz2)      bunzip2 $1      ;;
      *.rar)      rar x $1        ;;
      *.gz)       gunzip $1       ;;
      *.tar)      tar xf $1       ;;
      *.tbz2)     tar xjf $1      ;;
      *.tgz)      tar xzf $1      ;;
      *.zip)      unzip $1        ;;
      *.Z)        uncompress $1   ;;
      *)          echo "'$1' cannot be extracted via extract()" ;;
      esac
    else
      echo "'$1' is not a valid file"
      return 1
    fi
}

function nyancat() {
  telnet nyancat.dakko.us
}

function starwars() {
  telnet towel.blinkenlights.nl
}

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

function .jwsconsole() {
  jnlp=$(echo $HOME/Downloads/*.jnlp | grep -v '\*\.jnlp' | tail -n 1)
  if [ "x$jnlp" != "x" ]; then
    javaws $jnlp
    sleep 10
    rm $jnlp
  fi
}

export EDITOR=vim

fi
# vi: syntax=sh ts=2

