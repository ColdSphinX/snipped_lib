# Definition examples:
shopt -s extglob
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
      echo -e "\e[1;32m$PSPOST\e[m"
    else
      echo -e "\e[1;37m$PSPOST\e[m"
    fi
  elif ! $_ps_differ ; then
    echo -e "\e[1;33m$PSPOST\e[m"
  else
    echo -e "\e[1;31m$PSPOST\e[m"
  fi
}
function _ps_cmd() {
  local pst=(${PIPESTATUS[@]})
  local cmd=$(history 1 | sed 's/^.[[:space:]]*\([^[:space:]]\)/\1/')
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
}
PS1="$PSUSR@$PSHOST:\[\e[1;34m\]\w\[\e[m\]\[\$(_ps_exitcode \$(_ps_pipestatus))\] "
PS2='\[$(_ps_exitcode $(_ps_pipestatus))\] '
PS3=$(echo -en "\e[1;34m$PSPOST\e[m ")
export PS4='$(if [[ "$?" == "0" ]]; then echo -e "\e[1;32m$0:$LINENO\e[m($?)+" ; else echo -e "\e[1;31m$0:$LINENO\e[m($?)+" ; fi) '
PROMPT_COMMAND='_ps_cmd'

