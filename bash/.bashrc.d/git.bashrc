[[ $- != *i* ]] && return 0

# Git
# source https://github.com/henrik/dotfiles
function .mkgit() { 
  mkdir "$1" && cd "$1" && echo "#$1" >> README.md
  git init && git add README.md
  git commit -m "Initialized $1 repo with README.md"
  echo ">>> Initialized $1 repo with README.md"
}

# Returns the branch name as a string
# Restrict to use within other functions
function __branch(){
  git branch 2>/dev/null | grep ^\* | awk '{print $2}' | tr -d '\n'
}

# Automatically prepends branch name to commit
# Yells at you for using master
function branch:commit() {
  branch_name="$(__branch | tr '[:lower:]' '[:upper:]')"

  if [ $branch_name == 'MASTER' ]; then
    echo ">>> Current branch is master"
    echo ">>> Please move your changes to the appropriate branch"
    echo ">>> Aborting commit"
  else
    commit_message="$branch_name $@"

    git commit -am"$commit_message"
  fi
}

# Inserts branch name into the push command, accepts first argument for push destination
function branch:push() {
  branch_name="`__branch`"

  if [ -n "$1" ]; then
    remote="origin"
  else
    remote="$1"
  fi

  if [ $branch_name == 'master' ]; then
    echo ">>> Current branch is master"
    echo ">>> Please move your changes to the appropriate branch"
    echo ">>> Aborting commit"
  else
    git push $remote $branch_name
  fi
}

# Copies branch name to clipboard
function branch:copy(){
  branch_name=`__branch`;
  __branch | pbcopy
  echo "Copied '$branch_name' to the clipboard"
}

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

# vi: syntax=sh ts=2

