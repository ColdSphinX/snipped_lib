# only continue if in an interactive shell
[[ $- != *i* ]] && return 0

# don't continue if you are in a screen session!
[[ $TERM =~ ^screen ]] && return 0

# only continue if tmux is there
which tmux &>/dev/null || return 0

# try to attach to an detached tmux session
if [[ -z "$TMUX" ]] ; then
  # get the id of a deattached session
  ID="`tmux ls 2>/dev/null | grep -vm1 attached | cut -d: -f1`"
  if [[ -z "$ID" ]] ; then
    # if not available create a new one
    tmux new-session
  else
    # if available attach to it
    tmux attach-session -t "$ID"
  fi
  # exit shell immediadly after closing/detaching the tmux session
  # as long as you are not logged in as root
  [ $UID -ne 0 ] && exit
fi

