#!/bin/bash

cd "${0%/*}" || exit 1
INSTALLPATH="$(pwd)"
cd ..

echo "Stopping and unloading service"
MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
if [ "${MACOS_MAJOR:-0}" -ge 13 ]; then
    sudo launchctl bootout system /Library/LaunchDaemons/com.teclib.glpi-agent.plist
else
    sudo launchctl stop com.teclib.glpi-agent
    sudo launchctl unload /Library/LaunchDaemons/com.teclib.glpi-agent.plist
fi

# Still wait until process has been stopped
# shellcheck disable=SC2009
read -r PID _ <<<"$(ps -ec -o pid,command | grep glpi-agent)"
if [ "$PID" !=  "" ]; then
    (( TIMEOUT=300 ))
    while sudo kill -0 "$PID" 2>/dev/null
    do
        sleep .1
        (( --TIMEOUT )) || break
    done
    if [ "$TIMEOUT" == "0" ]; then
        echo "killing process: $PID"
        sudo kill "$PID"
    fi
fi

echo "Saving conf.d content, just in case"
if [ -d "$INSTALLPATH/etc/conf.d" ]; then
    cp -af "$INSTALLPATH/etc/conf.d" /tmp
fi

while read -r FILE
do
  echo "removing '$FILE'"
  [ -n "$FILE" ] && [ -e "$FILE" ] || continue
  sudo rm -f -R "$FILE"
done <<-FILES
    $INSTALLPATH
    /var/log/glpi-agent.log
    /usr/local/bin/dmidecode
    /Library/LaunchDaemons/com.teclib.glpi-agent.plist
FILES

# Unregister package
sudo pkgutil --forget com.teclib.glpi-agent "$INSTALLPATH"
