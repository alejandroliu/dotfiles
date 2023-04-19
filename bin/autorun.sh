#!/bin/sh
#~ export PATH=$PATH:$HOME/.bin:$HOME/.gitbin

(xdpyinfo | grep -q XVNC-EXTENSION) && IS_VIRTUAL=true

if ! $IS_VIRTUAL ; then
  :
  # type safeeyes && ( sleep 10 ; safeeyes ) &
  # type redshift-gtk && redshift-gtk & # Red shift display
fi

#~ if [ -n "$(pidof xconsole)" ] ; then
  #~ type xconsole-helper && xconsole-helper &
#~ fi

type pidgin && pidgin & # local chat client
# type parcellite && parcellite & # clipboard manager

