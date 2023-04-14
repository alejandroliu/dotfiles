#!/bin/sh
#
# This script will prepare geany.conf for commit
#
# Meant to remove changes that are not worth remembering.
#

sed \
	-e 's/^treeview_position=.*$//' \
	-e 's/^geometry=.*$//' \
	-e 's/^position_.*$//' \
	-e 's/^recent_files=.*$//' \
	-e 's/^current_page=.*$//' \
	-e 's/^FILE_NAME.*$//' \
	| uniq | sed -e 's/^/:/' -e 's/$/:/' | while read -r ln
	do
	  case "$ln" in
	  :active_plugins=*)
	    echo :active_plugins=$(
	      echo -n "$ln" | cut -d= -f2- | tr ';' '\n' | sort | tr '\n' ';' | sed -e 's/^;//'  -e 's/;$//'
	    )
	    continue
	    ;;
	  esac
	  echo "$ln"
	done \
	| sed -e 's/^://' -e 's/:$//'
