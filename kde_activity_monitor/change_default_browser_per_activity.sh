#!/usr/bin/env bash
##########################################################################
# Shellscript:  Change default browser depending which KDE activity you
#               are on.
# Author     :  Paco Orozco <paco@pacoorozco.info>
# Requires   :  kreadconfig5, kwriteconfig5, dbus-monitor
##########################################################################

##########################################################################
# CONFIGURATION
##########################################################################
DBUS_SERVICE=org.kde.ActivityManager
DBUS_INTERFACE="${DBUS_SERVICE}.Activities"
DBUS_PATH=/ActivityManager/Activities

##########################################################################
# DO NOT MODIFY BEYOND THIS LINE
##########################################################################

##########################################################################
# Main function
##########################################################################
function main() {
  dbus-monitor --profile "type=signal,path=${DBUS_PATH},interface=${DBUS_INTERFACE}" |
    while read -r _ _ _ _ _ _ _ currentEvent; do
      # read -r type timestamp serial sender destination path interface currentEvent  # Unused variables left for readability

      change_default_browser_on_activity_change "${currentEvent}"

    done
}

##########################################################################
# Functions
##########################################################################
function readconf() {
  kreadconfig5 --file ~/.config/kdeglobals --group General --key BrowserApplication
}

function writeconf() {
  kwriteconfig5 --file ~/.config/kdeglobals --group General --key BrowserApplication "$1"
}

function change_default_browser_on_activity_change() {
  # Act only on 'CurrentActivityChanged' event.
  [ "$1" == "CurrentActivityChanged" ] || return

  _currentActivityID=$(qdbus "${DBUS_SERVICE}" "${DBUS_PATH}" "${DBUS_INTERFACE}.CurrentActivity")
  _currentActivityName="$(qdbus "${DBUS_SERVICE}" "${DBUS_PATH}" "${DBUS_INTERFACE}.ActivityName" "${_currentActivityID}")"

  echo "Switched to activity ${_currentActivityName}"
  echo "Previous browser was $(readconf)"

  case "${_currentActivityName}" in
  Personal)
    writeconf firefox.desktop
    ;;
  Work)
    writeconf google-chrome.desktop
    ;;
  *) # default in case a new activity is created
    writeconf firefox.desktop
    ;;
  esac

  echo "Current browser is $(readconf)"
}

##########################################################################
# Main code
##########################################################################
main "$@"
