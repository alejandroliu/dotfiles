#!/bin/sh
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
if [ -f /etc/bashrc ] ; then
  . /etc/bashrc
fi

export HISTSIZE=5000 HISTFILESIZE=5000

#
# Custom prompt
#
# References:
# - https://askubuntu.com/questions/409611/desktop-notification-when-long-running-commands-complete
# - https://jichu4n.com/posts/debug-trap-and-prompt_command-in-bash/
# - https://stackoverflow.com/questions/6109225/echoing-the-last-command-run-in-bash
# - https://en.wikipedia.org/wiki/ANSI_escape_code
# - http://tldp.org/HOWTO/Bash-Prompt-HOWTO/index.html
# - https://stackoverflow.com/questions/16715103/bash-prompt-with-last-exit-code
#
PS1='[\u@\h \W]\$ '
NOTIFY_DELAY=15

_pre_command() {
  local incmd="$1"
  if [ x"$incmd" != x"$PROMPT_COMMAND" ] ; then
    if [ -n "$previous_command" ] ; then
      previous_command="$previous_command;$incmd"
    else
      previous_command="$incmd"
    fi
  fi

  if [ -z "$AT_PROMPT" ]; then
    return
  fi
  unset AT_PROMPT

  # Do stuff.
  _start=$SECONDS
}

_prompt_command() {
  local rv=$?
  local runtime=$(expr $SECONDS - $_start)
  AT_PROMPT=true

  local reset='\[\e[0m\]'
  if [ $rv -eq 0 ] ; then
    local clr='\[\e[0;102;30m\]' # green
  else
    local clr='\[\e[0;41;97m\]'	# red
  fi
  if [ $runtime -eq 1 ] ; then
    local s=''
  else
    local s='s'
  fi
  local eop='\[\[\e[K\e[0m\]'
  printf '\033[0;97;44m\033[K\033[0m'
  if [ -n "${WINDOW:-}" ] ; then
    local w="[#${WINDOW}]:"
  else
    local w=""
  fi
  echo -ne "\033]0;$(whoami)@$(uname -n):${PWD/#$HOME/\~}\007"
  PS1="${clr}${w}RV=$rv ($runtime sec$s) $reset"'[\u@\h \W]\$ '"$reset"
  #~ PS1="${clr}RV=$rv ($runtime sec$s) "'[\u@\h \W]\$ '"$reset"
  #~ PS1="${clr}RV=$rv ($runtime sec$s) $reset"'[\u@\h \W]\$ '"$clr$eop"

  if [ -n "$FIRST_PROMPT" ]; then
    unset FIRST_PROMPT
    return
  fi

  # Do stuff.
  if [ -n "$DISPLAY" ] ; then
    if type notify-send >/dev/null 2>&1 ; then
      if (( $runtime > $NOTIFY_DELAY )) ; then
	notify-send -a "Run $(set - $previous_command ; echo $1)" \
	"COMPLETED in $runtime secs" \
	"$previous_command"
      fi
    fi
  fi
  previous_command=""
}
FIRST_PROMPT=true
_start=$SECONDS
trap '_pre_command "$BASH_COMMAND"' DEBUG
PROMPT_COMMAND='_prompt_command'

# Bash checks the window size after each command and, if necessary,
# updates the values of LINES and COLUMNS
shopt -s checkwinsize
[ -d $HOME/.dotfiles/libpkgs/ecd ] && . $HOME/.dotfiles/libpkgs/ecd/cd.sh
[ -d $HOME/.bin ] && export PATH=$PATH:$HOME/.bin
[ -d $HOME/.gitbin ] && export PATH=$PATH:$HOME/.gitbin
if [ -n "$DISPLAY" ] ; then
  if [ "$(hostname)" = "pch3" ] ; then
    export MPT_AO=pulse
  fi
fi

#
# Aliases
#
alias more=less
alias moer=less
alias mroe=less
export LESS='-s -X -R'

alias fsd="$HOME/nethome/fsd"
alias ls='ls --color=auto'
alias mv='mv -i'
alias cp='cp -i'
alias pharx="phar extract -f"
alias pharl="phar list -f"
alias kj='exit'
alias py='python3'

alias qop=/usr/local/bin/op
complete -F _root_command op

#
# Functions
#
mkdircd(){
  mkdir "$1" && cd "$1"
}

ge() {
  if [ -z "$DISPLAY" ] ; then
    if [ -n "${EDITOR:-}" ] && type $EDITOR ; then
      $EDITOR "$@"
      return $?
    fi
    if type micro ; then
      micro "$@"
      return $?
    fi
    vi "$@"
    return $?
  fi
  if type wmctrl >/dev/null 2>&1 ; then
    local appwin=$(wmctrl -l -x | awk '$3 == "geany.Geany" { print $1}')
    if [ -n "$appwin" ] ; then
      echo "Activating running geany..."
      wmctrl -i -R "$appwin"
      geany "$@"
    else
      echo "Starting geany..."
      geany "$@" >> $HOME/.xsession-errors 2>&1 &
    fi
    return 0
  fi
  geany "$@" &
}

screen() {
  command screen "$@"
  rc=$?
  tput cup $(tput lines) 0
  return $rc
}

pkglst() {
  xbps-query -m | awk -F- -v OFS=- '{ $NF="" ; NF=NF-1; print}' | sort -u
}
pkgdiff() {
  local t=$(mktemp)
  pkglst > $t
  diff -u /var/log/install-pkgs.txt $t | grep -v '^ ' | grep -v '^@'
  rm -f $t
}

git_local_user() {
  [ $# -eq 0 ] && set - '--work'
  local mode name email
  while [ $# -gt 0 ]
  do
    case "$1" in
    --work) mode='work' ; name='Alejandro Liu' ; email='alejandrol@t-systems.com' ;;
    --personal) mode='personal' ; name='Alejandro Liu' ; email='alejandro_liu@hotmail.com' ;;
    *)
      echo 'Usage: $0 [--work|--personal]'
      return 0
    esac
    shift
  done 
  
  if [ ! -d '.git' ] ; then
    echo 'You must be a the root of a git repository when you run this command.'
    return 1
  fi
  local yn
  for yn in user.name user.email
  do
    git config --show-origin --get $yn
  done
  
  echo -n 'Configure local $mode addresses? (y/N) ' 1>&2
  read yn
  case "$yn" in
  y*|Y*)
    echo 'Configuring local addresses' 1>&2
    git config user.name "$name" || return 1
    git config user.email "$email" || return 1
    return 0
    ;;
  *)
    echo 'Aborting' 1>&2
    return 1
    ;;
  esac
}


# We do this last, to keep things cleaner
previous_command=""

