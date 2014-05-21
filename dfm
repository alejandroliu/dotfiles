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

do_install() {
  do_file_list | (while read LN
    src=$(cut -d: -f1 <<<"$LN")
    dst=$(cut -d: -f2 <<<"$LN")

    if [ -L "$HOME/$dst" ] ; then
      

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

verbose=:
do=:

while [ $# -gt 0 ]
do
  case "$1" in
    -v)
       verbose=verb
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

op="$1" ; shift || true
case "$op" in
  install)
    do_install "$@"
    exit $?
    ;;
  *)
    do_help
    exit $?
    ;;
esac
exit 1
