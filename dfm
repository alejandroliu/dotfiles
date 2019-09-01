#!/bin/sh
DFM_HOME=$(cd $(dirname $0) && pwd)
dotdir=$DFM_HOME/etc
sysname=$(uname -n)


fatal() {
  echo "$@" 1>&2
  exit 1
}

verb() {
  echo "$@" 1>&2
}

resolve_sln() {
  local target="$1" linknam="$2"

  [ -d "$linknam" ] && linknam=$linknam/$(basename $target)

  local linkdir=$(cd $(dirname $linknam) && pwd) || return 1
  local targdir=$(cd $(dirname $target) && pwd) || return 1

  linkdir=$(echo "$linkdir" | sed 's!^/!!' | tr ' /' '/ ')
  targdir=$(echo "$targdir" | sed 's!^/!!' | tr ' /' '/ ')

  local a b

  while true
  do
    set - $linkdir ; a="$1"
    set - $targdir ; b="$1"
    [ $a != $b ] && break
    set - $linkdir ; shift ; linkdir="$*"
    set - $targdir ; shift ; targdir="$*"
    [ -z "$linkdir" ] && break;
    [ -z "$targdir" ] && break;
  done

  if [ -n "$linkdir" ] ; then
    set - $linkdir
    local q=""
    linkdir=""
    while [ $# -gt 0 ]
    do
      shift
      linkdir="$linkdir$q.."
      q=" "
    done
  fi
  echo $linkdir $targdir $(basename $target) | tr '/ ' ' /'
}


dotfile_status() {
  local dotfile="$1" target="$2"

  if [ ! -e "$HOME/$dotfile" ] ; then
    echo "."
  elif [ ! -L "$HOME/$dotfile" ] ; then
    echo "file"
  else
    local cur="$(readlink $HOME/$dotfile)"
    if [ "$cur" = "$rdotdir/$target" ] ; then
      echo "OK"
    elif [ $(expr substr $cur 1 $rdotdir_ln) = $(expr substr $rdotdir/$target 1 $rdotdir_ln)  ] ; then
      echo "OLD $(expr substr $cur $(expr $rdotdir_ln + 1) 9999)"
    else
      echo "link $cur"
    fi
  fi
}

do_file_list() {
  find $dotdir -maxdepth 1 -type f -printf '%P\n' | \
      sed 's/=[^=]*$//' | sort -u | (
      while read LN
      do
	src=$LN
	dst=$(echo $LN | sed 's/^dot/./' | tr '^' '/' )
	[ -f $dotdir/$src=$sysname ] && src="$src=$sysname"
	echo $src:$dst
      done
  )
}

do_status() {
  do_file_list | (while read LN
    do
      local src=$(cut -d: -f1 <<<"$LN")
      local dst=$(cut -d: -f2 <<<"$LN")
      local cur=$(dotfile_status $dst $src)
      echo $dst:$src:$cur
    done
  )
}

do_install() {
  do_file_list | (while read LN
    do
      local src=$(cut -d: -f1 <<<"$LN")
      local dst=$(cut -d: -f2 <<<"$LN")
      local cur=$(dotfile_status $dst $src)

      case "$cur" in
	.)
	  $verbose symlinking $dst to $src
	  $do ln -s $rdotdir/$src $HOME/$dst
	  ;;
	file)
	  verb Conflict file: $dst
	  ;;
	OK)
	  $verbose $dst skipping, OK
	  ;;
	OLD*)
	  $verbose $dst updating to $src, pointing to old config: ${cur#OLD}
	  $do rm -f $HOME/$dst
	  $do ln -s $rdotdir/$src $HOME/$dst
	  ;;
	link*)
	  verb Conflict link $dst: ${cur#link}
	  ;;
      esac
    done
  )
}


do_help() {
  cat <<-'EOF'
	dfm - manages dot files

	Usage:
	    dfm [options] [cmd]

	Commands:

	    install	- install symlinks

	Options:

	    -v	- be verbose
	    -x	- execute mode
	EOF
}

rdotdir=$(resolve_sln $dotdir $HOME)
rdotdir_ln=$(expr $(expr length "$rdotdir") + 1)

verbose=verb
do=:

while [ $# -gt 0 ]
do
  case "$1" in
    -v)
       verbose=verb
       ;;
    -q)
       verbose=:
       ;;
    -x)
       do=""
       ;;
     *)
       break
       ;;
  esac
  shift
done

[ -n "$do" ] && verbose=verb
if [ $# -eq 0 ] ; then
  do_help
  exit 0
fi

op="$1" ; shift || true
case "$op" in
  install)
    do_install "$@"
    exit $?
    ;;
  status)
    do_status
    exit $?
    ;;
  *)
    do_help
    exit $?
    ;;
esac
exit 1
