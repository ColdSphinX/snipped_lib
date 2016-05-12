SH=$(basename ${0/-/})
#[[ "$SHELL" = "/bin/bash" && -z "$BASH_VERSION" ]] && SH=dash

case $SH in
  bash)
    ARSTART=0
    export HOST=$HOSTNAME
  ;;
  zsh)
    ARSTART=1
    export HOSTNAME=$HOST
    alias shopt=':'
    alias _expand=_bash_expand
    alias _complete=_bash_comp
    autoload colors && colors
    emulate -L sh
    setopt kshglob noshglob braceexpand
  ;;
  dash)
    alias source="."
    ARSTART=0
    export HOST=$HOSTNAME
    echo "You really wanna use dash?" >&2
    echo "Please use bash!" >&2
    echo "Or kill yourself..." >&2
  ;;
esac

export PATH=${PATH/$HOME\/bin:/}
if [ -d ${HOME}/.rbenv/bin ]; then
  # prevent doublications in the PATH
  export PATH=${PATH/${HOME}\/.rbenv\/shims:/}
  if ! (echo $PATH | grep -q "${HOME}/.rbenv/bin"); then
    export PATH="${PATH}:${HOME}/.rbenv/bin"
  fi
  eval "$(rbenv init -)"
  # and now, force the added path on the possition _I_ want in PATH and not the one they want.
  # below /usr/local/bin !
  path_a=($(echo $PATH | sed 's/:/ /g'))
  shims=-1
  usrlocal=-1
  # find the 2 positions, no need to break...there aren't that many entrys and this way we can solve both in one loop.
  for ((ii=$ARSTART;ii<${#path_a[@]};ii++))
  do
    if [[ "${path_a[$ii]}" = "$HOME/.rbenv/shims" ]]; then
      shims=$ii
    fi
    if [[ "${path_a[$ii]}" = "/usr/local/bin" ]]; then
      usrlocal=$(($ii - 1))
    fi
  done
  if ! [[ $shims -lt 0 || $usrlocal -lt 0 ]]; then
    # a lazy bubbesort like loop
    if [[ $shims -lt $usrlocal ]]; then
      cache=""
      for ((ii=$shims;ii<$usrlocal;ii++))
      do
        cache="${path_a[$ii]}"
        path_a[$ii]="${path_a[$(($ii+1))]}"
        path_a[$(($ii+1))]="$cache"
      done
    fi
  fi
  export PATH=$(echo "${path_a[@]}" | sed 's/ /:/g')
  unset path_a cache ii shims usrlocal
fi
if ! (echo $PATH | grep -q "$HOME/bin"); then
  export PATH="$HOME/bin:$PATH"
fi
if ! (echo $PATH | grep -q "$HOME/sbin"); then
  export PATH="$HOME/sbin:$PATH"
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
alias .devoffile=devoffile

function emptythedir() {
  local blank=$(mktemp -d)
  rsync --delete "$blank/" "$1/"
  rm -r $blank
}

function clear() {
  echo -ne "\e[m"
  eval $(_bin clear)
  echo -n ""
  printf "\033c"
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
  if in_path calc ; then
    $(in_path -p calc) "$*" | _strip
  else
    echo "$*" | bc -l
  fi
}

function clc() { 
  echo "$*" | bc -l; 
}

function _run_with_nvim() {
  local cmd="$1"
  shift
  if in_path "$cmd" ; then
    if [[ "$1" == "-e" ]]; then
    shift
      if in_path nvim ; then
        $(in_path -p nvim) "term://$cmd $*"
      else
        $(in_path -p "$cmd") $*
      fi
    else
      $(in_path -p "$cmd") $*
    fi
  else
    echo "Please install $cmd" >&2
  fi
}
function htop() {
  _run_with_nvim htop $*
}
function mtr() {
  local param="-n -4 -t"
  if [[ "$1" == "-e" ]]; then
    param="-e $param"
    shift
  fi
  _run_with_nvim mtr $param $*
}

unset rsync_proxy
if [[ -z "$no_proxy" ]]; then
  export no_proxy="localhost,127.0.0.1,$HOSTNAME"
fi

if [[ $- =~ i ]]; then


if type -a nvim &>/dev/null ; then
  export EDITOR=nvim
  alias vim=nvim
  alias vi=nvim
  alias ex="nvim -e"
  alias exim="nvim -E"
  alias view="nvim -R"
  alias rvim="nvim -Z"
  alias rview="nvim -RZ"
elif type -a vim &>/dev/null ; then
  export EDITOR=vim
  alias vi=vim
elif type -a nano &>/dev/null ; then
  export EDITOR=nano
elif type -a vi &>/dev/null ; then
  export EDITOR=vi
elif type -a emacs &>/dev/null ; then
  export EDITOR=emacs
fi

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'

    # colored GCC warnings and errors
    export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
fi

alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias lr='ls -lachtr'

alias config_show="grep -E -v '^(|[[:space:]]*#.*)$'"
alias apg="/usr/bin/apg -a 1 -n 10 -m 12 -x 12"

alias hist='history | grep'
alias ,="ssh -l root"
alias _='mosh --ssh="ssh -l root"'
alias psg='ps -Alf | grep'

# failsafe :D
alias :q=' exit'
alias :Q=' exit'
alias :x=' exit'
alias cd..='cd ..'

alias ,bashrc="source $HOME/.bashrc"
alias ,bashrced="$EDITOR $HOME/.bashrc $HOME/.bashrc.d/*.bashrc"
alias .showvars="(env | egrep -v '^(PS4|PS3|HISTTIMEFORMAT|LS_COLORS|_)=' ; set ) | grep --color=always '^[^[:space:]]*=' | sort -u"

alias docker_attach="docker attach --sig-proxy=false"

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


function sslchecker() {
  local DOMAIN=$1
  local PORT=$2
  local SERVER=$3
  [ -z $PORT ] && PORT=443
  [ -z $SERVER ] && SERVER=$DOMAIN

  echo "Domain: $DOMAIN"
  echo | openssl s_client -CApath /etc/ssl/certs/ -servername $DOMAIN -connect $SERVER:$PORT | openssl x509 -noout -dates
}

[[ $- != *i* ]] && return 0

function .nyancat() {
  telnet nyancat.dakko.us
  clear
}

function .starwars() {
  telnet towel.blinkenlights.nl
  clear
}

function .sysinfo() {
  echo "sh: $(readlink -f /bin/sh)"
  echo "Host: $(hostname -f)"
  echo "Up:  $(uptime)"
  echo "Load: $(cat /proc/loadavg)"
  [[ -n "$DISPLAY" ]] && echo "Display: $DISPLAY"
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

function in_path() {
  local PATHA=($(echo $PATH | sed 's/:/ /g'))
  local found=false
  local checkpath=false
  if [[ "$1" == "-p" ]]; then
    checkpath=true
    shift
  fi
  local file=$(basename "$1")
  local dir=$(dirname "$1")
  if [[ "$dir" != "." ]]; then
    checkpath=true
    if ! (echo "$dir" | grep -q '^/'); then
      dir="$PWD/$dir"
    fi
  fi
  dir=$(echo "$dir" | sed 's_//_/_g')
  for ((i=$ARSTART;i<${#PATHA[@]};i++))
  do
    if [[ -x "${PATHA[$i]}/$file" ]]; then
      found=true
      if $checkpath; then
        if [[ "${PATHA[$i]}" != "$dir" ]]; then
          echo "${PATHA[$i]}/$file"
        fi
      fi
      break
    fi
  done
  $found
}

function .rescan_disks() {
  # rescan for disks
  local id=''
  for id in /sys/class/fc_host/*
  do
    echo "1" > "$id/issue_lip"
  done
  for id in /sys/class/scsi_host/*
  do
    echo "- - -" > "$id/scan"
  done
  for id in /sys/class/scsi_device/*:*:*:*
  do
    echo 1 "$id/device/rescan"
  done
}

function .rescan_partitions() {
  # rescan partitions
  local path=''
  local disk=''
  for path in /sys/block/sd?
  do
    disk=$(basename $path)
    echo 1 > /sys/block/$disk/device/rescan
  done
}

fi

if [ "$COLORTERM" = "gnome-terminal" ] || [ "$COLORTERM" = "xfce4-terminal" ]; then
    export TERM=xterm-256color
elif [ "$COLORTERM" = "rxvt-xpm" ]; then
    export TERM=rxvt-256color
fi

# vi: syntax=sh ts=2

