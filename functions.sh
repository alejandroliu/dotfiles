#!/bin/sh
#
# My collection of user functions
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
