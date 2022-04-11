#! /bin/sh

# This script can be used to setup a linux portable agent:
# 1. copy an AppImage linux installer in a folder
# 2. copy this script in the same folder
# 3. run this script one time as root
# Now the choosen folder contains all required script and environment to start
# the agent in a portable way:
#  * etc/ subfolder contains any required configuration
#  * var/ subfolder will contains hostname subfolder to keep current deviceid
#    depending on current computer. This permits to run the agent on different
#    computers if they have different hostname.

cd "${0%/*}"

: ${APPIMAGE:=$(echo glpi-agent*.AppImage 2>/dev/null)}

if [ -z "${APPIMAGE%\**}" ]; then
    echo "No AppImage is $PWD, set it via APPIMAGE environment variable" >&2
    exit 1
fi

if [ -z "${APPIMAGE%%* *}" ]; then
    echo "Too much AppImage found in $PWD, select one via APPIMAGE environment variable or remove the wrong ones" >&2
    echo "Found: $APPIMAGE" >&2
    exit 1
fi

if [ ! -e "$APPIMAGE" ]; then
    echo "No such AppImage: $APPIMAGE" >&2
    exit 1
elif [ ! -x "$APPIMAGE" ]; then
    chmod +x "$APPIMAGE"
fi

if [ "${APPIMAGE%/*}" == "$APPIMAGE" ]; then
    APPIMAGE="./$APPIMAGE"
fi

[ -d var ] || mkdir var
if [ ! -d etc ]; then
    echo "Setup glpi-agent..."
    if [ "$(id -u)" -ne "0" ]; then
        echo "Can't copy etc folder from AppImage, run $0 as root" >&2
        exit 1
    fi
    echo "Copying etc folder from AppImages..."
    OFFSET=$("$APPIMAGE" --appimage-offset)
    [ -d mnt ] || mkdir mnt
    mount "$APPIMAGE" mnt/ -o offset=$OFFSET \
        || exit 1
    cp -a mnt/usr/share/glpi-agent/etc etc
    umount mnt
    rmdir mnt
    [ -d etc/conf.d ] || mkdir etc/conf.d
    echo "vardir = var" >etc/conf.d/00-vardir.cfg

    echo "Create scripts..."
    for script in glpi-agent glpi-inventory glpi-netdiscovery glpi-netinventory glpi-esx glpi-injector glpi-remote
    do
        case $script in
            glpi-agent)  OPTS="--conf-file=etc/agent.cfg --vardir=\"\$VARDIR\"" ;;
            glpi-remote) OPTS="--vardir=\"\$VARDIR\"" ;;
            *)           OPTS="" ;;
        esac
        cat >$script <<SCRIPT
#! /bin/sh
cd "\${0%/*}"
source ./glpi-agent-portable.sh
exec "$APPIMAGE" --script=$script $OPTS \$*
SCRIPT
        chmod +x $script
    done
    cat >perl <<PERL
#! /bin/sh
source "\${0%/*}/glpi-agent-portable.sh"
exec "$APPIMAGE" --perl \$*
PERL
    chmod +x perl
    echo "Glpi Agent linux portable is ready"
fi

# vardir will depend on current hostname
VARDIR=var/$HOSTNAME
[ -d "$VARDIR" ] || mkdir "$VARDIR"
