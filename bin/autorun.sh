#!/bin/sh

if type gsettings ; then
  # Make sure we have a more windows like settings...
  gsettings set org.mate.Marco.global-keybindings show-desktop '<Mod4>d' #'<Control><Alt>d'
  gsettings set org.mate.Marco.global-keybindings panel-main-menu '<Control>Escape' #'<Alt>F1'
  gsettings set org.mate.Marco.window-keybindings maximize '<Mod4>Up'
  gsettings set org.mate.Marco.window-keybindings minimize '<Mod4>Down'
  gsettings set org.mate.Marco.window-keybindings tile-to-side-w '<Mod4>Left'
  gsettings set org.mate.Marco.window-keybindings tile-to-side-e '<Mod4>Right'
fi

IS_VIRTUAL=false
if (xdpyinfo | grep -q XVNC-EXTENSION) ; then
  IS_VIRTUAL=true
fi

if ! $IS_VIRTUAL ; then
  type safeeyes && safeeyes & # Run SafeEyes
  # type redshift-gtk && redshift-gtk & # Red shift display
  type xbindkeys && xbindkeys & # Configure HotKeys

  # Really make double sure that this is set-up properly
  setxkbmap -rules evdev -model evdev -layout us -variant altgr-intl
  setxkbmap -option keypad:pointerkeys
fi

type xconsole-helper && xconsole-helper &

#~ type owncloud && owncloud & # Sync NextCloud
type parcellite && parcellite & # Clipboard manager
type pidgin && pidgin & # local chat client


