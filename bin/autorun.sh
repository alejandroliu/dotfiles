#!/bin/sh
is_xrdp() {
  [ -z "$DISPLAY" ] && return 1
  local port=$(echo $DISPLAY | cut -d . -f1 | tr -d :)
  local xorgpid=$(ss -lxp | awk '$5 == "/tmp/.X11-unix/X'"$port"'" {
      if (match($0, /,pid=([0-9]+)/,arr)) {
        print arr[1];
      }
    }')
  [ -z "$xorgpid" ]  && return 1
  local sesspid=$(awk '$1 == "PPid:" { print $2 }' /proc/$xorgpid/status)
  [ -z "$sesspid" ] && return 1
  local name=$(awk '$1 == "Name:" { print $2 }' /proc/$sesspid/status)
  if [ x"$name" = x"xrdp-sesman" ] ; then
    return 0
  fi
  return 1
}

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
elif is_xrdp ; then
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
( # Clipboard manager
  exec > .parcellite.log 2>&1
  type parcellite || exit 0
  sleep 10
  parcellite
) &
type pidgin && pidgin & # local chat client


