# only continue if in an interactive shell
[[ $- != *i* ]] && return 0

if [[ "$HOSTNAME" != "${worklaptop}" ]]; then
  .sysinfo
fi
if [[ -n "$TMUX" ]] ; then
  echo -e "\e[0;37m[Press <Ctrl+Q D> to detach session]\e[m" >&2
fi

# don't continue if you are in a screen session!
[[ $TERM =~ ^screen ]] && return 0

# only continue if tmux is there
which tmux &>/dev/null || return 0

# try to attach to an detached tmux session
if [[ -z "$TMUX" ]] ; then
  # get the id of a deattached session
  TID="`tmux ls 2>/dev/null | grep -vm1 attached | cut -d: -f1`"
  if type -a wemux &>/dev/null ; then
    wemux j $USER &>/dev/null
    WID="`wemux ls 2>/dev/null | grep -vm1 attached | cut -d: -f1`"
  fi
  if ! _ssh_workstation ; then
    if type -a wemux &>/dev/null ; then
      if ( type -a wemux &>/dev/null && [[ "$USER" == "$me" ]] ); then
        select session in wemux tmux
        do
          break
        done
      fi
      ${session:-wemux} new-session -s "$(_ssh_incoming -v -s)_$!"
    else
      tmux new-session -s "$(_ssh_incoming -v -s)_$!"
    fi
  elif [[ -n "$BYOBU_BACKEND" ]] ; then
    if type -a wemux &>/dev/null ; then
      if ! (wemux l | grep -q '^No wemux servers currently active\.') &>/dev/null ; then
        WEMUX_SRVS="$(wemux l | grep '[0-9]*\.' | awk '{print $2}') /bin/bash"
        select server in $WEMUX_SRVS
        do
          case $server in
          "/bin/bash") break ;;
          *)
            wemux j $server
            wemux
            exit
          ;;
          esac
        done
      fi
    fi
  elif type -a byobu &>/dev/null ; then
    (wemux l | grep -q '^No wemux servers currently active\.') &>/dev/null || \
    echo -e "$(wemux l)\nPlease attach from a plain shell!"
    byobu
  elif [[ -z "$WID" && -z "$TID" ]] ; then
    # if not available create a new one
    if type -a wemux &>/dev/null ; then
      wemux new-session
    else
      tmux new-session
    fi
  elif [[ -n "$WID" ]] ; then
    # if available attach to it
    wemux attach-session -t "$WID"
  elif [[ -n "$TID" ]] ; then
    # if available attach to it
    tmux attach-session -t "$TID"
  fi
  if [[ -z "$BYOBU_BACKEND" ]] ; then
    if ! _ssh_workstation ; then
      exit
    elif [[ $UID -ne 0 ]]; then
      exit
    elif ( type -a byobu &>/dev/null ) ; then
      if [[ ! -e /root/.notmux ]]; then
        exit
      fi
    fi
  fi
fi

# vi: syntax=sh ts=2

