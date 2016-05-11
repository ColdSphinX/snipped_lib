export HISTTIMEFORMAT='%F_%T  '

shopt -s extglob

function _ssh_incoming() {
  local verbose=false
  local short=false
  [[ "$1" == "-v" ]] && verbose=true
  [[ "$2" == "-s" ]] && short=true
  if [[ -n "$SSH_CONNECTION" ]]; then
    local remoteip=$(echo $SSH_CONNECTION | awk '{print $1}')
    local remotehost=$remoteip
    if host $remoteip &>/dev/null ; then
      remotehost=$(LANG=C host $remoteip 2>&1 | sed 's/^.*pointer \(.*\)./\1/' | grep -v '^loopback')
      # take the first host; if you want to add filters, do it here
      remotehost=$(egrep -o '^[^[:space:]]*' <(echo $remotehost))
      if $short ; then
        remotehost=$(sed 's/^\([^\.]*\)\..*$/\1/' <(echo $remotehost))
      fi

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

PROMPT_DIRTRIM=3
if [[ $UID -eq 0 ]]; then
  PSPOST='#'
  PSUCOL='1;31'
else
  PSPOST='>'
  PSUCOL='1;32'
fi
case $SH in
  zsh)
    PSUSR=$(echo -e "%{\e[${PSUCOL}m%}%n%{\e[m%}")
  ;;
  *)
    PSUSR="\[\e[${PSUCOL}m\]$USER\[\e[m\]"
  ;;
esac
if _ssh_incoming ; then
  if _ssh_workstation ; then
    case $SH in
      zsh) PSRHOST=$(echo -e "%{\e[1;33m%}") ;;
      *)   PSRHOST='\[\e[1;33m\]' ;;
    esac
  else
    case $SH in
      zsh) PSRHOST=$(echo -e "%{\e[1;31m%}") ;;
      *)   PSRHOST='\[\e[1;31m\]' ;;
    esac
  fi
  case $SH in
    zsh) PSRHOST=$PSRHOST$(_ssh_incoming -v -s)$(echo -e "%{\e[m%}->") ;;
    *)   PSRHOST=$PSRHOST$(_ssh_incoming -v -s)'\[\e[m\]->' ;;
  esac
fi
case $HOSTNAME in
  ${WORKSTATIONS})
    PSHCOL='1;32'
    ;;
  ${TESTSERVERS})
    PSHCOL='1;33'
    ;;
  *)
    PSHCOL='1;31'
    ;;
esac
case $SH in
  zsh) PSHOST=$(echo -e "%{\e[${PSHCOL}m%}%m%{\e[m%}") ;;
  bash|dash)   PSHOST='\[\e[${PSHCOL}m\]$HOSTNAME\[\e[m\]' ;;
  *)   PSHOST='\[\e[${PSHCOL}m\]$HOSTNAME\[\e[m\]' ;;
esac
function _ps_pipestatus() {
  case $SH in
    zsh) local pst=(${pipestatus[@]}) ;;
    *)   local pst=(${PIPESTATUS[@]}) ;;
  esac
  local fail=false
  local x
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
    echo -en "\e[1;32m"
  else
    echo -en "\e[1;31m"
  fi
  if [[ $_ps_change == $_ps_differ ]]; then
    echo -en "\e[2m"
  fi
}
function _ps_cmd() {
  local pst=(${PIPESTATUS[@]})
  local cmd=$(history 1 | sed -e 's/^.[[:blank:]]*[[:digit:]]*  [[:digit:]:_-]\{19\}  //' -e 's/\([^[:space:]]\)[[:space:]]*$/\1/')
  _ps_current=$(history 1 | awk '{print $1}')
  _ps_differ=false
  _ps_change=false
  local fail=false

  [ -z "$_ps_last" ] && _ps_last=$_ps_current

  if [[ "$_ps_current" != "$_ps_last" ]]; then
    _ps_differ=true
  elif [[ "$_ps_last_pst" != "${pst[@]}" ]]; then
    _ps_change=true
  fi
  if [[ "$_ps_change" != "$_ps_differ" ]]; then
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

  local _batt_last=${CURRENT_BATTERY/.*/}
  local _cable_last=$CURRENT_CABLE
  _battery
  if [[ "$_cable_last" != "$CURRENT_CABLE" ]]; then
    if $CURRENT_CABLE; then
      echo -e "\e[0;33m<Cable plugged in>\e[m"
    else
      echo -e "\e[0;33m<Cable plugged off>\e[m"
      if [[ ${_batt_last:-0} -ne ${CURRENT_BATTERY/.*/} ]]; then
        if [[ $CURRENT_BATTERY -lt 20 ]]; then
          echo -e "\e[0;33m<Battery low: \e[1m$CURRENT_BATTERY%\e[m\e[0;33m>\e[m"
        fi
      fi
    fi
  fi

  _ps_last_pst=${pst[@]}
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
function _battery() {
  local BATTERY_DIR=/proc/acpi/battery/BAT0
  local AC_DIR=/proc/acpi/ac_adapter/AC

  if [[ -d "$BATTERY_DIR" ]]; then
    if grep -q 'last full capacity' ${BATTERY_DIR}/info ; then
      local full_batery=$( awk '/last full capacity/ {print $4}' ${BATTERY_DIR}/info )
      local current_battery=$( awk '/remaining capacity/ {print $3}' ${BATTERY_DIR}/state )
      local battery_percent=$(printf '%.2f' $( echo "${current_battery} / ${full_batery} * 100" | bc -l))
      CURRENT_BATTERY=$battery_percent
    fi
  else
    CURRENT_BATTERY=0
  fi
  if [[ -d "$AC_DIR" ]]; then
    if grep -q on-line ${AC_DIR}/state; then
      CURRENT_CABLE=true
    else
      CURRENT_CABLE=false
    fi
  else
    CURRENT_CABLE=true
  fi
}

case $SH in
  bash|dash)
    PS1="$PSUSR@$PSRHOST$PSHOST:\[\e[1;34m\]\w\[\e[m\]:\[\$(_ps_git)\]\$_ps_branch\[\e[m\]\[\$(_ps_exitcode \$(_ps_pipestatus))\]\$PSPOST\[\e[m\] "
    PS2="\[\$(_ps_git)\]\$_ps_branch\[\e[m\]\[\$(_ps_exitcode \$(_ps_pipestatus))\]\$PSPOST\[\e[m\] "
    PS3=$(echo -en "\e[1;34m$PSPOST\e[m ")
    PS4BASE='$0:$LINENO:\#\e[m($?)+'
    PS4="\$(if [[ \"\$?\" -eq 0 ]]; then echo -e \"\e[1;32m$PS4BASE\" ; else echo -e \"\e[1;31m$PS4BASE\" ; fi) "
    #PROMPT_COMMAND=",bashrc"
    PROMPT_COMMAND='_ps_cmd'
  ;;
  zsh)
    PS1="$PSUSR@$PSRHOST$PSHOST:$(echo -e "%{\e[1;34m%}%$PROMPT_DIRTRIM~%{\e[m%}:%{\e[1;37m%}")%?$PSPOST$(echo -e "%{\e[m%}") "
    PS2="%_>"
    PS3=$(echo -en "\e[1;34m$PSPOST\e[m ") 
    PS4="%x:%I:%i(%?)+ "
    PROMPT_COMMAND='_ps_cmd'
  ;;
  *)
    PS1="$USER@$HOSTNAME$PSPOST "
    PS2="> "
    PS3="> "
    PS4="+ "
  ;;
esac

# vi: syntax=sh ts=2

