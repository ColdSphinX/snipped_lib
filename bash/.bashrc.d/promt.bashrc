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
function _ps_pipestatus() {
  local pst=(${PIPESTATUS[@]})
  local fail=false
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
  local cmd=$(history 1 | sed 's/^.[[:blank:]]*[[:digit:]]*  [[:digit:]:_-]\{19\}  //')
  _ps_current=$(history 1 | awk '{print $1}')
  _ps_differ=false
  local fail=false

  [ -z "$_ps_last" ] && _ps_last=$_ps_current

  if [[ "$_ps_current" != "$_ps_last" ]]; then
    _ps_differ=true
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
PS1="$PSUSR@$PSHOST:\[\e[1;34m\]\w\[\e[m\]:\[\$(_ps_git)\]\$_ps_branch\[\e[m\]\[\$(_ps_exitcode \$(_ps_pipestatus))\]\$PSPOST\[\e[m\] "
PS2="\[\$(_ps_git)\]\$_ps_branch\[\e[m\]\[\$(_ps_exitcode \$(_ps_pipestatus))\]\$PSPOST\[\e[m\] "
PS3=$(echo -en "\e[1;34m$PSPOST\e[m ")
export PS4='$(if [[ "$?" == "0" ]]; then echo -e "\e[1;32m$0:$LINENO\e[m($?)+" ; else echo -e "\e[1;31m$0:$LINENO\e[m($?)+" ; fi) '
PROMPT_COMMAND='_ps_cmd'

