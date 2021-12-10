#!/bin/bash

cd "${0%/*}"
INSTALLPATH="`pwd`"
cd ..

echo "Stopping and unloading service"
sudo launchctl stop org.glpi-project.glpi-agent
sudo launchctl unload /Library/LaunchDaemons/org.glpi-project.glpi-agent.plist

# Still wait until process has been stopped
read PID XXX <<<`ps -ec -o pid,command | grep glpi-agent`
if [ "$PID" !=  "" ]; then
    let TIMEOUT=300
    while sudo kill -0 $PID 2>/dev/null
    do
        sleep .1
        (( --TIMEOUT )) || break
    done
    if [ "$TIMEOUT" == "0" ]; then
        echo "killing process: $PID"
        sudo kill $PID
    fi
fi

echo "Saving conf.d content, just in case"
if [ -d "$INSTALLPATH/etc/conf.d" ]; then
    cp -af "$INSTALLPATH/etc/conf.d" /tmp
fi

while read FILE
do
  echo "removing '$FILE'"
  [ -n "$FILE" -a -e "$FILE" ] || continue
  sudo rm -f -R "$FILE"
done <<-FILES
    $INSTALLPATH
    /var/log/glpi-agent.log
    /usr/local/bin/dmidecode
    /Library/LaunchDaemons/org.glpi-project.glpi-agent.plist
FILES

# Unregister package
sudo pkgutil --forget org.glpi-project.glpi-agent $INSTALLPATH
