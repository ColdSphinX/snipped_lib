export HISTTIMEFORMAT='%F_%T  '

shopt -s extglob

# Definition examples:
#WORKSTATIONS='@(work1|workmobile)'
#TESTSERVERS='@(test0|testA)'

PROMPT_DIRTRIM=3
PSPOST='>'
PSUSR="\[\e[1;32m\]\u\[\e[m\]"
if [[ $UID -eq 0 ]]; then
  PSPOST='#'
  PSUSR="\[\e[1;31m\]\u\[\e[m\]"
fi
if _ssh_incoming ; then
  if _ssh_workstation ; then
    PSRHOST='\[\e[1;33m\]'
  else
    PSRHOST='\[\e[1;31m\]'
  fi
  PSRHOST=$PSRHOST$(_ssh_incoming -v -s)'\[\e[m\]->'
fi
case $HOSTNAME in
  ${WORKSTATIONS})
    PSHOST='\[\e[1;32m\]\h\[\e[m\]'
    ;;
  ${TESTSERVERS})
    PSHOST='\[\e[1;33m\]\h\[\e[m\]'
    ;;
  *)
    PSHOST='\[\e[1;31m\]\h\[\e[m\]'
    ;;
esac
function _ssh_incoming() {
  local verbose=false
  local short=false
  [[ "$1" == "-v" ]] && verbose=true
  [[ "$2" == "-s" ]] && short=true
  if [[ -n "$SSH_CONNECTION" ]]; then
    local remoteip=$(echo $SSH_CONNECTION | awk '{print $1}')
    local remotehost=$remoteip
    if host $remoteip &>/dev/null ; then
      remotehost=$(LANG=C host $remoteip 2>&1 | sed 's/^.*pointer \(.*\)./\1/')
      # take the first host; if you want to add filters, do it here
      remotehost=$(egrep -o '^[^[:space:]]*' <(echo $remotehost))
      $short && remotehost=$(sed 's/^\([^\.]*\)\..*$/\1/' <(echo $remotehost))
    fi
  fi
  if [[ -n "$remotehost" ]]; then
    $verbose && echo $remotehost
    return 0
  else
    $verbose && hostname
    return 1
  fi
}
function _ssh_workstation() {
  local verbose=false
  [[ "$1" == "-v" ]] && verbose=true
  local remotehost=$HOSTNAME
  if _ssh_incoming ; then
    remotehost=$(_ssh_incoming -v -s)
  fi
  $verbose && echo $remotehost
  case $remotehost in
    ${WORKSTATIONS})
      return 0
    ;;
    *)
      return 1
    ;;
  esac
}
function _ps_pipestatus() {
  local pst=(${PIPESTATUS[@]})
  local fail=false
  local x=''
  for x in ${pst[@]}
  do
    if [[ $x -ne 0 ]]; then
      fail=true
      break
    fi
  done
  echo ${pst[@]}
  if $fail; then
    return 1
  else
    return 0
  fi
}
function _ps_exitcode() {
  if [[ "$1" == "0" ]]; then
    if $_ps_differ ; then
      echo -en "\e[1;32m"
    else
      echo -en "\e[1;37m"
    fi
  elif ! $_ps_differ ; then
    echo -en "\e[1;33m"
  else
    echo -en "\e[1;31m"
  fi
}
function _ps_cmd() {
  local pst=(${PIPESTATUS[@]})
  local cmd=$(history 1 | sed -e 's/^.[[:blank:]]*[[:digit:]]*  [[:digit:]:_-]\{19\}  //' -e 's/\([^[:space:]]\)[[:space:]]*$/\1/')
  _ps_current=$(history 1 | awk '{print $1}')
  _ps_differ=false
  local fail=false

  [ -z "$_ps_last" ] && _ps_last=$_ps_current

  if [[ "$_ps_current" != "$_ps_last" ]]; then
    _ps_differ=true
    local x=''
    for x in ${pst[@]}
    do
      if [[ $x -ne 0 ]]; then
        fail=true
        break
      fi
    done
    if $fail ; then
      echo -e "\e[0;33m<${cmd}> returned: ${pst[@]}\e[m"
    fi
  fi
  _ps_last=$_ps_current
  _ps_branch=$(git branch 2>/dev/null | grep ^\* | awk '{print $2}' | tr -d '\n')
  if [[ $UID -eq 0 ]]; then
    PSPOST='#'
  else
    PSPOST='>'
  fi
}
function _ps_git() {
  if [[ -n "$_ps_branch" ]]; then
    case $_ps_branch in
      master) echo -en "\e[1;31m" ;;
      *test*) echo -en "\e[1;33m" ;;
      *) echo -en "\e[1;32m" ;;
    esac
  fi
}
PS1="$PSUSR@$PSRHOST$PSHOST:\[\e[1;34m\]\w\[\e[m\]:\[\$(_ps_git)\]\$_ps_branch\[\e[m\]\[\$(_ps_exitcode \$(_ps_pipestatus))\]\$PSPOST\[\e[m\] "
PS2="\[\$(_ps_git)\]\$_ps_branch\[\e[m\]\[\$(_ps_exitcode \$(_ps_pipestatus))\]\$PSPOST\[\e[m\] "
export PS3=$(echo -en "\e[1;34m$PSPOST\e[m ")
export PS4='$(if [[ "$?" == "0" ]]; then echo -e "\e[1;32m$0:$LINENO\e[m($?)+" ; else echo -e "\e[1;31m$0:$LINENO\e[m($?)+" ; fi) '
PROMPT_COMMAND='_ps_cmd'
# vi: syntax=sh ts=2

