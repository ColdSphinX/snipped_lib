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
  WID="`wemux ls 2>/dev/null | grep -vm1 attached | cut -d: -f1`"
  if ! _ssh_workstation ; then
    if type -a wemux &>/dev/null ; then
      wemux new-session -s "$(_ssh_incoming -v -s)"
    else
      tmux new-session -s "$(_ssh_incoming -v -s)"
    fi
  elif [[ -n "$BYOBU_BACKEND" ]] ; then
    true
  elif type -a byobu &>/dev/null ; then
    [[ -z "$WID" ]] && echo -e "$(wemux list)\nPlease attach from a plain shell!"
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

