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

cd "$(dirname "$0")"

: ${APPIMAGE:=}

if [ -z "$APPIMAGE" ]; then
    OTHERS=""
    for appimage in $(ls -1t glpi-agent*.AppImage 2>/dev/null)
    do
        if [ -z "$APPIMAGE" ]; then
            APPIMAGE="$appimage"
        else
            [ -n "$OTHERS" ] && OTHERS="$OTHERS "
            OTHERS="$OTHERS$appimage"
        fi
    done
fi

if [ ! -e "$APPIMAGE" ]; then
    echo "No AppImage in $PWD, set it via APPIMAGE environment variable" >&2
    exit 1
fi

if [ -n "$OTHERS" ]; then
    echo "More than one AppImage found in $PWD, you may need to select one via APPIMAGE environment variable or remove the wrong ones" >&2
    echo "Others found: $OTHERS" >&2
    echo "Selected one: $APPIMAGE" >&2
fi

if [ ! -e "$APPIMAGE" ]; then
    echo "No such AppImage: $APPIMAGE" >&2
    exit 1
elif [ ! -x "$APPIMAGE" ]; then
    chmod +x "$APPIMAGE"
fi

# Use relative path to current folder if necessary
if [ "$( basename "$APPIMAGE" )" = "$APPIMAGE" ]; then
    APPIMAGE="./$APPIMAGE"
    APPIMAGE_FULLPATH="$(pwd)/$APPIMAGE"
else
    APPIMAGE_FULLPATH="$APPIMAGE"
fi

[ -d var ] || mkdir var
if [ ! -d etc ]; then
    echo "Setup glpi-agent..."
    if [ "$(id -u)" -ne "0" ]; then
        echo "Can't copy etc folder from AppImage, run $0 as root" >&2
        exit 1
    fi
    echo "Copying etc folder from AppImage..."
    OFFSET=$("$APPIMAGE" --appimage-offset)
    [ -d mnt ] || mkdir mnt
    if ! mount "$APPIMAGE" mnt/ -o offset=$OFFSET; then
        echo "Failed to mount AppImage" >&2
        exit 1
    fi
    cp -a mnt/usr/share/glpi-agent/etc etc
    umount mnt
    rmdir mnt
    [ -d etc/conf.d ] || mkdir etc/conf.d
    echo "vardir = var" >etc/conf.d/00-vardir.cfg
fi

if [ -e glpi-agent ]; then
    echo "Updating scripts..."
else
    echo "Creating scripts..."
fi
for script in glpi-agent glpi-inventory glpi-netdiscovery glpi-netinventory glpi-esx glpi-injector glpi-remote
do
    case $script in
        glpi-agent)  OPTS="--conf-file=etc/agent.cfg --vardir=\"\$VARDIR\"" ;;
        glpi-remote) OPTS="--vardir=\"\$VARDIR\"" ;;
        *)           OPTS="" ;;
    esac
    cat >$script <<SCRIPT
#! /bin/sh

cd "\$(dirname "\$0")"

# vardir will depend on current hostname
if [ -z "\$HOSTNAME" ]; then
    VARDIR="var/\$(hostname)"
else
    VARDIR="var/\$HOSTNAME"
fi

[ -d "\$VARDIR" ] || mkdir "\$VARDIR"

if [ -x "$APPIMAGE" ]; then
    exec "$APPIMAGE" --script=$script $OPTS \$*
else
    echo "$APPIMAGE not available in \$(pwd)" >&2
    exit 1
fi
SCRIPT
    chmod +x $script
done

cat >perl <<PERL
#! /bin/sh
if [ -x "$APPIMAGE_FULLPATH" ]; then
    exec "$APPIMAGE_FULLPATH" --perl \$*
elif [ -x "$APPIMAGE" ]; then
    exec "$APPIMAGE" --perl \$*
else
    echo "$APPIMAGE_FULLPATH can't be run" >&2
    echo "$APPIMAGE not available in \$(pwd)" >&2
    exit 1
fi
PERL
chmod +x perl
echo "Glpi Agent linux portable is ready"
