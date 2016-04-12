if [[ $- =~ i ]]; then

alias .gs="git status"
alias .gw="git show"
alias .gw^="git show HEAD^"
alias .gw^^="git show HEAD^^"
alias .gd="git diff-index HEAD -p --color"  # What's changed? Both staged and unstaged.
alias .gdo="git diff --cached"  # What's changed? Only staged (added) changes.
alias .gcaf="git add --all && gcof"
alias .gcof="git commit --no-verify -m"
alias .gpp='git pull --rebase && git push'
alias .gppp="git push -u"  # Can't pull because you forgot to track? Run this.
alias .gps='(git stash --include-untracked | grep -v "No local changes to save") && .gpp && git stash pop || echo "Fail!"'
alias .go="git checkout"
alias .gb="git checkout -b"
alias .got="git checkout -"
alias .gom="git checkout master"
alias .gr="git branch -d"
alias .grr="git branch -D"
alias .gcp="git cherry-pick"
alias .gam="git commit --amend"
alias .gamm="git add --all && git commit --amend -C HEAD"
alias .gammf=".gamm --no-verify"
alias .gba="git rebase --abort"
alias .gbc="git add -A && git rebase --continue"
alias .gbm="git fetch origin master && git rebase origin/master"
alias .gsu='git submodule update'
alias .checkout='git checkout'
alias .pull='git pull'

function .mkgit() { 
  mkdir "$1" && cd "$1" && echo "#$1" >> README.md
  git init && git add README.md
  git commit -m "Initialized $1 repo with README.md"
  echo ">>> Initialized $1 repo with README.md"
}

fi
# vi: syntax=sh ts=2

