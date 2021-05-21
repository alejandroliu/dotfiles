#!/bin/sh
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
if [ -f /etc/bashrc ] ; then
  . /etc/bashrc
fi


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
	notify-send "COMPLETED in $runtime secs" "$previous_command"
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
if [ -n "$DISPLAY" ] ; then
  if [ "$(hostname)" = "pch3" ] ; then
    export MPT_AO=pulse
  fi
fi

#
# Aliases
#
alias ls='ls --color=auto'
alias mv='mv -i'
alias cp='cp -i'
alias moer=more
alias mroe=more
alias pharx="phar extract -f"
alias pharl="phar list -f"
alias kj='exit'
alias gc='glibc'

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
    if type ne ; then
      ne "$@"
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

# We do this last, to keep things cleaner
previous_command=""
