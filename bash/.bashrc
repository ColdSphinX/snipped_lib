# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# Debugging
function source() {
  [[ $- = *i* ]] && echo "loading \"$1\" ..." >&2
  builtin source $*
  local rc=$?
  [[ $- = *i* && $rc -ne 0 ]] && echo -e "\e[1;31mfailed to load \"$1\"\e[m" >&2
  return $rc
}

for source in $HOME/.bashrc.d/*.bashrc
do
  if [[ -f "${source}" ]]; then
    source "${source}"
  fi
done

# vi: syntax=sh ts=2

