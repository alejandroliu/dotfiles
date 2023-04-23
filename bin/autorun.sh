#!/bin/sh
#~ export PATH=$PATH:$HOME/.bin:$HOME/.gitbin
sleep 3 # Delay so that sytem tray is ready

(xdpyinfo | grep -q XVNC-EXTENSION) && IS_VIRTUAL=true || IS_VIRTUAL=false

#~ if ! $IS_VIRTUAL ; then
  #~ if (type safeeyes && ! (ps x | grep python | grep safeeyes)); then
    #~ # Safe eyes is not running yet
    #~ safeeyes &
  #~ fi
  #~ # type redshift-gtk && redshift-gtk & # Red shift display
#~ fi

#~ if [ -n "$(pidof xconsole)" ] ; then
  #~ type xconsole-helper && xconsole-helper &
#~ fi

#~ type pidgin && pidgin & # local chat client
# type parcellite && parcellite & # clipboard manager

