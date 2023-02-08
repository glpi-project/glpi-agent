#! /bin/bash

: ${NETSIMDIR:=var/netsim.001}
: ${NETSIMDIRLINK:=var/netsim}
: ${SUBCOMMAND:=}
: ${ARGS:=}
: ${SERVER:=}
: ${TAG:=}
: ${SUDO:=sudo}
: ${IP:=127.9.0.1}
: ${AGENTPORT:=62354}
: ${SNMPPORT:=161}
: ${COMMUNITY:=public}
: ${ENCRYPT:=}

# snmpsim seems to have been abandoned but inexio is maintaining it in a fork name thola-snmpsim
: ${SNMPSIM:=thola-snmpsim}
: ${SNMPSIMURL:=https://github.com/inexio/snmpsim/archive/master.zip}

let SETDEFAULT=0 SYSTEM=0 AGENTPID=0 STARTED=0 DEBUG=0 INVENTORY=1
let LINES=$(tput lines) RELOADLINES=EPOCHSECONDS+5

function _setsubcommand {
    if [ -z "$SUBCOMMAND" ]; then
        SUBCOMMAND="$1"
    else
        case "$SUBCOMMAND" in
            setup|server|tag|debug|port|ip|import|walk|setup|delete|backup|restore)
                [ -n "$ARGS" ] && ARGS="$ARGS "
                ARGS="$ARGS$1"
                ;;
            *)
                echo "Only one subcommand supported at a time on commandline" >&2
                exit 1
                ;;
        esac
    fi
}

while [ -n "$1" ]
do
    case "$1" in
        --help|-h)
            cat <<HELP
Usage:
    netsim.sh [-h|--help] [start]

    Manage a network devices simlator other dedicated ips and a GLPI Agent to
    test NetDiscovery and NetInventory tasks.

Options:
    -h --help           Show the help
    -n --netsim         Dedicated folder to use as netsim environment
    -D --default        Set netsim as default netsim environment
    -S --system         Firstly use system agent in place of repository one
    -s --server <URL>   Set GLPI Agent server target URL
    -t --tag <TAG>      Set GLPI Agent tag
    -p --port <PORT>    Set GLPI Agent port
    --sudo              Start GLPI Agent with sudo

Sub-commands:
    start               Start currently configured network or a default one
HELP
            ;;
        --server*|-s)
            if [ -z "${1%--server=*}" ]; then
                SERVER="${1#--server=}"
            else
                shift
                SERVER="$1"
            fi
            ;;
        --tag*|-s)
            if [ -z "${1%--tag=*}" ]; then
                TAG="${1#--tag=}"
            else
                shift
                TAG="$1"
            fi
            ;;
        --port*|-p)
            if [ -z "${1%--port=*}" ]; then
                AGENTPORT="${1#--port=}"
            else
                shift
                AGENTPORT="$1"
            fi
            ;;
        --netsim|-n)
            shift
            if [ -z "$1" ]; then
                echo "No netsim folder provided" >&2
                exit 1
            fi
            NETSIMDIR="$1"
            ;;
        --default|-D)
            let SETDEFAULT=1
            ;;
        --sudo)
            SUDO=sudo
            ;;
        --system|-S)
            let SYSTEM=1
            ;;
        -*)
            echo "Ignoring unsupported '$1' option" >&2
            ;;
        *)
            _setsubcommand "$1"
            ;;
    esac
    shift
done

function stream {
    if (( EPOCHSECONDS > RELOADLINES )); then
        let LINES=$(tput lines) RELOADLINES=EPOCHSECONDS+5
    fi
    if (( ONESHOT )); then
        echo -e "$*"
    else
        tput -S <<TPUT
            sc
            csr 0 $((LINES-2))
            cup $((LINES-2)) 0
TPUT
        echo -ne "\n$*"
        tput -S <<TPUT
            csr 0 $((LINES-1))
            rc
TPUT
    fi
}

function _stream_pipe {
    IFS=
    while read line
    do
        stream "$line"
    done
}

function _setup_default_environment {
    # Just link NETSIMDIR to var/netsim by default
    if [ ! -e "$NETSIMDIRLINK" -o -h "$NETSIMDIRLINK" ]; then
        rm -f "$NETSIMDIRLINK"
        # Set NETSIMDIR as absolute path if relative to be linked properly
        [ -n "${NETSIMDIR%%/*}" ] && NETSIMDIR="$PWD/$NETSIMDIR"
        if ! ln -sf "$NETSIMDIR" "$NETSIMDIRLINK"; then
            echo "Failed to link '$NETSIMDIR' as default netsim environment"
            exit 1
        fi
    else
        echo "'$NETSIMDIRLINK' exists and is not a link, aborting" >&2
        exit 1
    fi
}

(( SETDEFAULT )) && _setup_default_environment

function _load_environment {
    if [ ! -d "$NETSIMDIR" ]; then
        if [ -d "$NETSIMDIRLINK/etc" ]; then
            stream "Using setup default environment"
            NETSIMDIR="$NETSIMDIRLINK"
        elif ! mkdir -p "$NETSIMDIR/etc/conf.d"; then
            echo "Failed to create GLPI Agent conf folder in netsim environment under '$NETSIMDIR'" >&2
            exit 1
        fi
    fi
    if [ -e "$NETSIMDIR/env" ]; then
        source "$NETSIMDIR/env"
        [ "$SYSTEM_AGENT" == "1" ] && let SYSTEM=1
    fi
    if [ ! -e "$NETSIMDIR/encrypt/teclib.pubkey.pem" ];then
        [ -d "$NETSIMDIR/encrypt" ] || mkdir -p "$NETSIMDIR/encrypt"
        # Storing Teclib public to securely share walks in backup
        cat >"$NETSIMDIR/encrypt/teclib.pubkey.pem" <<TECLIB_PUBLIC_KEY
-----BEGIN PUBLIC KEY-----
MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEA2dtPb0cgk2FP2PjFTcu+
OqlE3Y1JzG7cb/dLoC8b0CrOGn1+9FD9UJLUkkcaX8B79BlpNjzLWFPkvUxUvmFL
Bq17IcYjvV1jp/rVjrnVjVDxB9GMRFA1HAuRdtl6tBcggOjjoj7763thg+53Xzv7
kgUh3rfvN1cvmh5JV/63R4wueio8+TlAaE0GOLgeLJvG2t6T1Yl3g5Aofyaw2Ouz
ODjjiBxfEkapipsUdB16nXUNjeK/zlHxpGNnZefRCCUe4la62k7iWKQwUWm4AqLD
JfUcKfG30bvuVT3ogGj6/1vPqliuJOvKzqCpo5na9y/ucqBPmKPmlC4P7z97fJlb
1vMR0WceAMRnOqW2Dq/kpMIY/OqlUE2Yl+oYZyi8VG1q/gY+O+V7unW03nZo2LoK
sABeQQhsWnq0D13Ryc+bkrHTeV9RSaHeZhpdYGanwUK39ZgJF5RImWeXI6E+FBMA
LuEz9Nqf+c1jo6+QabRIxoi6N5Js3z2UAAVTvK98tvhc279C3hteoNLAsWK0hTY8
J4Hn5/YvTimnVG1R1BrI4VVCLeuwKIZkti8vGrjOx5WincuFwzrTaj3A6TVLyJkv
Jf5HVjXuKg+u1b3ezyMJ9gj5v1DBQ9v2VkrLDInN6ygZeNhW4E87h5/9YRm996Mw
ItSW7+3LlidVWXaT6Snj8aECAQM=
-----END PUBLIC KEY-----
TECLIB_PUBLIC_KEY
    fi
}

function _setup_environment {
    if [ ! -d "$NETSIMDIR/venv" ]; then
        stream "Creating dedicated python virtual environment..."
        if ! virtualenv "$NETSIMDIR/venv"; then
            echo "Failed to create Python Virtualenv under '$NETSIMDIR'" >&2
            which virtualenv
            exit 1
        fi
        # Remove netsim variation scripts generating not useful error messages during walk import
        rm -f "$NETSIMDIR/venv/share/snmpsim/variation/{sql,redis}.py"
    fi
    stream "Loading dedicated python virtual environment..."
    source "$NETSIMDIR/venv/bin/activate"
    if ! pip show $SNMPSIM 2>/dev/null; then
        if ! pip install --upgrade pip; then
            echo "Failed to upgrade pip under Python Virtualenv" >&2
            exit 1
        fi
        # Install with url if set or from pip repository
        if ! pip install ${SNMPSIMURL:=$SNMPSIM}; then
            echo "Failed to install snmpsim under Python Virtualenv" >&2
            exit 1
        fi
        pip show $SNMPSIM
    fi
    if [ ! -d "$NETSIMDIR/templates" ]; then
        mkdir -p "$NETSIMDIR/templates"
        if [ -d resources/walks ]; then
            for name in sample3 sample4
            do
                if [ -e resources/walks/$name.walk ]; then
                    stream "Importing $name walk from repository as device template..."
                    mkdir "$NETSIMDIR/templates/$name"
                    sed -e 's/^iso\./.1./' resources/walks/$name.walk >"$NETSIMDIR/templates/$name/snmpwalk"
                    if ! snmpsim-manage-records --ignore-broken-records \
                        --source-record-type=snmpwalk --input-file="$NETSIMDIR/templates/$name/snmpwalk" \
                        --destination-record-type=snmprec --output-file="$NETSIMDIR/templates/$name/device.snmprec" 2>/dev/null | _stream_pipe; then
                        stream "Failed to import $name walk"
                        rm -rf "$NETSIMDIR/templates/$name"
                    fi
                    rm -f "$NETSIMDIR/templates/$name/snmpwalk"
                fi
            done
        fi
    fi
    [ -d "$NETSIMDIR/encrypt" ] || mkdir -p "$NETSIMDIR/encrypt"
    stream "Netsim environment was setup under '$NETSIMDIR' folder"
}

function _start_agent {
    # Agent is expected to be started from a cloned repository
    AGENT="bin/glpi-agent"
    if (( SYSTEM )); then
        AGENT=$( which glpi-agent )
        if [ -z "$AGENT" ]; then
            echo "No GLPI Agent installed on the system, please install one" >&2
            exit 1
        fi
    fi
    if [ ! -x "$AGENT" ]; then
        if [ -e "netsim.sh" && -x "../bin/glpi-agent" ]; then
            AGENT="bin/glpi-agent"
            cd ..
        else
            echo "Can't start GLPI Agent" >&2
            echo "Try to run this script from repository folder or install one and use -S option" >&2
            exit 1
        fi
    fi
    AGENT_VERSION=$("$AGENT" --version)
    if [ -z "$AGENT_VERSION" ]; then
        echo "Unable to start '$AGENT' from '$PWD'" >&2
        exit 1
    fi
    stream "Starting $AGENT_VERSION..."
    if [ ! -e "$NETSIMDIR/etc/agent.cfg" ]; then
        if (( INVENTORY )); then
            TASKS="inventory,netdiscovery,netinventory"
        else
            TASKS="netdiscovery,netinventory"
        fi
        cat >"$NETSIMDIR/etc/agent.cfg" <<DEFAULT_CONF
tasks = $TASKS
vardir = $NETSIMDIR
logger = stderr
debug = $DEBUG
httpd-port = $AGENTPORT
httpd-trust = 127.0.0.1
include conf.d
DEFAULT_CONF
        # Also enable toolbox to scan can be tested from http://120.0.0.1:$PORT/toolbox
        cat >"$NETSIMDIR/etc/toolbox-plugin.cfg" <<TOOLBOX_CONF
disabled = no
TOOLBOX_CONF
        cat >"$NETSIMDIR/etc/toolbox.yaml" <<TOOLBOX_YAML
configuration:
  updating_support: yes
  credentials_navbar: yes
  inventory_navbar: yes
  iprange_navbar: yes
  mibsupport_navbar: yes
  results_navbar: yes
TOOLBOX_YAML
    fi
    {
        $SUDO "$AGENT" --conf-file="$NETSIMDIR/etc/agent.cfg" --daemon --listen \
            --no-fork --pidfile="$NETSIMDIR/agent.pid" 2>&1 | _stream_pipe
    }&
    let STREAM_PID=$!
    while [ ! -s "$NETSIMDIR/agent.pid" ]; do sleep 1; done
    let AGENTPID=$(<"$NETSIMDIR/agent.pid")
    stream "Started $AGENT_VERSION with pid=$AGENTPID..."
}

function _stop_agent {
    if (( AGENTPID )); then
        stream "Stopping $AGENT_VERSION with pid=$AGENTPID..."
        $SUDO kill $AGENTPID 2>/dev/null
        [ -n "$STREAM_PID" ] && wait $STREAM_PID
        while [ -s "$NETSIMDIR/agent.pid" ]; do sleep 1; done
    fi
}

function _reload_conf {
    if (( STARTED )); then
        $SUDO kill -HUP $AGENTPID
        sleep 1
    else
        stream "Netsim not started"
    fi
}

function _run {
    if (( STARTED )); then
        $SUDO kill -USR1 $AGENTPID
    else
        stream "Netsim not started"
    fi
}

function _stop {
    if (( STARTED )); then
        stream "Stopping..."
        # Stop devices
        DEVICES=$( ls -d "$NETSIMDIR"/device-* 2>/dev/null )
        if [ -n "$DEVICES" ]; then
            for folder in $DEVICES
            do
                let N=${folder#$NETSIMDIR/device-}
                if [ -e "$NETSIMDIR/device-$N/agent.pid" ]; then
                    PID=$($SUDO cat "$NETSIMDIR/device-$N/agent.pid")
                    if [ -n "$PID" ]; then
                        stream "Stopping device-$N (pid=$PID)..."
                        $SUDO kill -USR1 $PID
                    fi
                    $SUDO rm -f "$NETSIMDIR/device-$N/agent.pid"
                fi
            done
        fi
        _stop_agent
        stream "Stopped"
        trap - EXIT
        let STARTED=0
    else
        stream "Netsim not started"
    fi
}

function _start {
    if (( STARTED )); then
        stream "Netsim still started"
    else
        stream "Starting..."
        _start_agent
        # Now start devices
        unset PROCESS_USER
        [ -n "$SUDO" ] && PROCESS_USER="--process-user=$(id -un) --process-group=$(id -gn)"
        DEVICES=$( ls -d "$NETSIMDIR"/device-* 2>/dev/null )
        COMMAND="$(which snmpsim-command-responder-lite)"
        COMMAND="${COMMAND/~/$HOME}"
        [ "${NETSIMDIR:0:1}" == "/" ] && RUNSIMDIR="$NETSIMDIR" || RUNSIMDIR="$PWD/$NETSIMDIR"
        if [ -n "$DEVICES" -a -x "$COMMAND" ]; then
            for folder in $DEVICES
            do
                let N=${folder#$NETSIMDIR/device-}
                if [ ! -e "$NETSIMDIR/device-$N/env" ]; then
                    stream "Skipping device-$N as not fully setup"
                    continue
                fi
                _IP=$(source "$NETSIMDIR/device-$N/env"; echo $IP)
                _PORT=$(source "$NETSIMDIR/device-$N/env"; echo $PORT)
                name=$(source "$NETSIMDIR/device-$N/env"; echo $NAME)
                stream "Starting device-$N: $name on $_IP:$_PORT..."
                [ -d "$NETSIMDIR/device-$N/cache" ] || mkdir "$NETSIMDIR/device-$N/cache"
                $SUDO "$COMMAND" --log-level=error --daemonize $PROCESS_USER \
                        --agent-udpv4-endpoint=$_IP:$_PORT \
                        --data-dir="$RUNSIMDIR/device-$N" \
                        --cache-dir="$RUNSIMDIR/device-$N/cache" \
                        --pid-file="$RUNSIMDIR/device-$N/agent.pid"
            done
            sleep 1
            for folder in $DEVICES
            do
                if [ ! -e "$folder/agent.pid" ]; then
                    stream "Failed to start ${folder##*/}"
                fi
            done
        fi
        stream "Started"
        trap _stop EXIT
        let STARTED=1
    fi
}

function _debug {
    let CURRENT_DEBUG=$DEBUG
    let DEBUG=0
    case "$1" in
        2) let DEBUG=2 ;;
        0) let DEBUG=0 ;;
        1|*) let DEBUG=1 ;;
    esac
    if (( CURRENT_DEBUG != DEBUG )); then
        stream "Setting GLPI Agent debug level to $DEBUG..."
        echo "debug = $DEBUG" >"$NETSIMDIR/etc/conf.d/debug.cfg"
        _reload_conf
    else
        stream "GLPI Agent debug level still at $DEBUG"
    fi
}

function _server {
    if [ -n "$1" ]; then
        SERVER=$1
        stream "Setting GLPI Agent server target to $SERVER..."
        echo "server = $SERVER" >"$NETSIMDIR/etc/conf.d/server.cfg"
        _reload_conf
    elif [ -n "$SERVER" ]; then
        stream "Current GLPI Agent server: $SERVER"
    else
        stream "No server set in GLPI Agent configuration"
    fi
}

function _tag {
    if [ -n "$1" ]; then
        TAG=$1
        stream "Setting GLPI Agent tag to $TAG..."
        echo "tag = $TAG" >"$NETSIMDIR/etc/conf.d/tag.cfg"
        _reload_conf
    elif [ -n "$TAG" ]; then
        stream "Current GLPI Agent tag: $TAG"
    else
        stream "No tag set in GLPI Agent configuration"
    fi
}

function _port {
    if [ -n "$1" ]; then
        AGENTPORT=$1
        stream "Setting GLPI Agent httpd port to $AGENTPORT..."
        echo "httpd-port = $AGENTPORT" >"$NETSIMDIR/etc/conf.d/port.cfg"
        _reload_conf
    elif [ -n "$AGENTPORT" ]; then
        stream "Current GLPI Agent httpd port: $AGENTPORT"
    else
        stream "No httpd port set in GLPI Agent configuration"
    fi
}

function _inventory {
    if [ -n "$1" -a "$1" != "$INVENTORY" ]; then
        INVENTORY=$1
        if (( "$INVENTORY" )); then
            stream "Enabling GLPI Agent inventory task..."
            TASKS="inventory,netdiscovery,netinventory"
        else
            stream "Disabling GLPI Agent inventory task..."
            TASKS="netdiscovery,netinventory"
        fi
        echo "tasks = $TASKS" >"$NETSIMDIR/etc/conf.d/tasks.cfg"
        _reload_conf
    elif (( "$INVENTORY" )); then
        stream "GLPI Agent inventory task is enabled"
    else
        stream "GLPI Agent inventory task is disabled"
    fi
}

function _sudo {
    if (( STARTED )); then
        stream "Netsim still started, can't change sudo usage"
    else
        case $1 in
            sudo)
                if [ "$SUDO" != "sudo" ]; then
                    SUDO=sudo
                    stream "Will use sudo to start netsim"
                else
                    stream "Still using sudo to start netsim"
                fi
                ;;
            *)  if [ "$SUDO" == "sudo" ]; then
                    # Fix ownership of anyfile under netsim environment
                    $SUDO chown -R $(id -un) "$NETSIMDIR"
                    stream "Won't use sudo to start netsim"
                else
                    stream "Still not using sudo to start netsim"
                fi
                unset SUDO
                ;;
        esac
    fi
}

function _system {
    if (( STARTED )); then
        stream "Netsim still started, can't change system agent usage"
    else
        case $1 in
            sys)
                if (( SYSTEM )); then
                    stream "Still using system GLPI Agent"
                else
                    let SYSTEM=1
                    stream "Try to use GLPI Agent from the system"
                fi
                ;;
            *)  unset SYSTEM
                if (( SYSTEM )); then
                    stream "Try to use GLPI Agent from current repository folder"
                else
                    stream "Still using GLPI Agent from current repository folder"
                fi
                ;;
        esac
    fi
}

function _ip {
    ARG="$1"
    case "$ARG" in
        +*)
            let PLUS=${ARG#+}
            read IP1 IP2 IP3 IP4 <<< ${IP//./ }
            let IP4+=PLUS
            while (( IP4 >= 255 ))
            do
                if (( IP4 <= 256 )); then
                    IP4=1
                else
                    let IP4-=256
                fi
                let IP3++
                if (( IP3 >= 255 )); then
                    let IP3=0 IP2++
                    (( IP2 >= 255 )) && let IP2=0
                fi
            done
            IP=$IP1.$IP2.$IP3.$IP4
            ;;
        -*)
            let MINUS=${ARG#-}
            read IP1 IP2 IP3 IP4 <<< ${IP//./ }
            let IP4-=MINUS
            while (( IP4 < 1 ))
            do
                if (( IP4 >= -1 )); then
                    IP4=254
                else
                    let IP4+=256
                fi
                let IP3--
                if (( IP3 <= 0 )); then
                    let IP3=254 IP2--
                    (( IP2 <= 0 )) && let IP2=254
                fi
            done
            IP=$IP1.$IP2.$IP3.$IP4
            ;;
        [:digit:].[:digit:].[:digit:].[:digit:])
            IP=$ARG
            ;;
    esac
    echo "Current IP: $IP"
}

function _import {
    _FILES="$*"
    if [ -z "$_FILES" ]; then
        read -p "Give walk files to import as template: " _FILES
        if [ -z "$_FILES" ]; then
            stream "No file provided"
            return
        fi
    fi
    for file in $_FILES
    do
        if [ -e "$file" ]; then
            name="${file##*/}"
            name="${name%.*}"
            let I=0
            # Get a not existing name
            while [ -d "$NETSIMDIR/templates/$name" ]
            do
                SUFFIX="-$I"
                name="${name%$SUFFIX}-$((++I))"
            done
            stream "Importing walk as '$name' device template..."
            mkdir "$NETSIMDIR/templates/$name"
            if ! snmpsim-manage-records --ignore-broken-records \
                --input-file="$file" --source-record-type=snmpwalk \
                --destination-record-type=snmprec --output-file="$NETSIMDIR/templates/$name/device.snmprec" 2>/dev/null; then
                stream "Failed to import $file"
                rm -rf "$NETSIMDIR/templates/$name"
            fi
        else
            stream "Missing $file, skipping"
        fi
    done
}

function _templates {
    if [ -d "$NETSIMDIR/templates" ]; then
        let COUNT=0
        for folder in "$NETSIMDIR"/templates/*
        do
            if [ -d "$folder" ]; then
                (( COUNT++ )) || stream "Available templates:"
                stream ${folder#$NETSIMDIR/templates/}
            fi
        done
    else
        stream "Templates list is empty"
    fi
}

function _setup {
    name="$*"
    if [ -z "$name" ]; then
        stream "No template name provided"
    elif [ -d "$NETSIMDIR/templates/$*" ]; then
        let I=0
        while [ -d "$NETSIMDIR/device-$I" ]
        do
            let I++
        done
        mkdir "$NETSIMDIR/device-$I"
        cp -a "$NETSIMDIR/templates/$name/device.snmprec" "$NETSIMDIR/device-$I/$COMMUNITY.snmprec"
        read -p "Give an ip to listen on: [$IP] " _IP
        [ -n "$_IP" ] && IP=$_IP
        read -p "Give a port to listen on: [$SNMPPORT] " _PORT
        [ -n "$_PORT" ] && SNMPPORT=$_PORT
        stream "Setting up $name as device on $IP:$SNMPPORT"
        cat >"$NETSIMDIR/device-$I/env" <<CONFIG
NAME=$name
IP=$IP
PORT=$SNMPPORT
CONFIG
        _ip +1
    else
        stream "Unknown $* template, skipping"
    fi
}

function _devices {
    DEVICES=$( ls -d "$NETSIMDIR"/device-* 2>/dev/null )
    if [ -n "$DEVICES" ]; then
        printf "%-3s   %-15s   %-5s   %s\n" ID IP PORT NAME | _stream_pipe
        for folder in $DEVICES
        do
            let N=${folder#$NETSIMDIR/device-}
            _IP=$(source "$NETSIMDIR/device-$N/env"; echo $IP)
            _PORT=$(source "$NETSIMDIR/device-$N/env"; echo $PORT)
            name=$(source "$NETSIMDIR/device-$N/env"; echo $NAME)
            printf "%-3s   %-15s   %-5s   %s\n" $N $_IP $_PORT $name | _stream_pipe
        done
    else
        stream "No device has been setup"
    fi
}

function _delete {
    if (( STARTED )); then
        stream "Netsim still started, skipping device deletion"
    else
        index="$*"
        if [ -d "$NETSIMDIR/device-$index" ]; then
            stream "Removing device $index..."
            rm -rf "$NETSIMDIR/device-$index"
        else
            stream "No such device: '$index'"
        fi
    fi
}

function _cleanup {
    if (( STARTED )); then
        stream "Netsim still started, stop before asking cleanup"
        return 1
    elif [ -n "$NETSIMDIR" -a -d "$NETSIMDIR" ]; then
        stream "Removing simulation environment under '$NETSIMDIR' folder..."
        $SUDO rm -rf "$NETSIMDIR"
    fi
}

function _reset {
    if (( STARTED )); then
        stream "Netsim still started, stop it before asking reset"
    else
        _cleanup
        _load_environment
        [ "$DEBUG" != "0" ] && _debug $DEBUG
        [ -n "$SERVER" ] && _server
        [ -n "$TAG" ] && _tag
        _port
        _devices
        _ip
    fi
}

function _walk {
    _IP="$1"
    if [ -z "$_IP" ]; then
        read -p "Give the ip of the device to make a walk on: " _IP
        if [ -z "$_IP" ]; then
            stream "No ip provided"
            return
        fi
    fi
    read -p "Give a name for the template to generate: " _NAME
    if [ -z "$_NAME" ]; then
        stream "No name provided"
        return
    fi
    read -p "Give the snmp version [2c]: " _VERSION
    if [ -z "$_VERSION" ]; then
        _VERSION=2c
    elif [ "$_VERSION" != "1" -a "$_VERSION" != "2c" ]; then
        stream "Unsupported snmp version"
        return
    fi
    read -p "Give the community: [$COMMUNITY] " _COMMUNITY
    [ -z "$_COMMUNITY" ] && _COMMUNITY=$COMMUNITY
    if [ -d "$NETSIMDIR/templates/$_NAME" ]; then
        stream "Template name still used, skipping"
    elif ! mkdir -p "$NETSIMDIR/templates/$_NAME"; then
        stream "Failed to create template folder: $NETSIMDIR/templates/$_NAME"
    elif snmpsim-record-commands --agent-udpv4-endpoint $_IP \
        --use-getbulk --start-object 1.0 --continue-on-errors 1 \
        --destination-record-type snmprec \
        --output-file "$NETSIMDIR/templates/$_NAME/device.snmprec" \
        --protocol-version $_VERSION --community $_COMMUNITY 2>&1 | _stream_pipe; then
        if [ -s "$NETSIMDIR/templates/$_NAME/device.snmprec" ]; then
            stream "Walk finished, $_NAME template created"
        else
            stream "Got no answer from $_IP"
            rm -rf "$NETSIMDIR/templates/$_NAME"
        fi
    else
        stream "Walk failure, $_NAME template not created"
        rm -rf "$NETSIMDIR/templates/$_NAME"
    fi
}

function _pub_encrypt {
    if [ -z "$ENCRYPT" ]; then
        stream "Archive content encryption not enabled, can't encrypt"
    elif [ ! -e "encrypt/$ENCRYPT.pubkey.pem" ]; then
        stream "Archive content public key for '$ENCRYPT' authority is missing, can't encrypt"
    else
        openssl pkeyutl -encrypt -in "$1" -pubin -inkey "encrypt/$ENCRYPT.pubkey.pem" -out "$1.$ENCRYPT" 2>&1 | _stream_pipe;
    fi
}

function _pub_decrypt {
    _KEYNAME="${1##*.}"
    if [ -z "$_KEYNAME" ]; then
        stream "Archive content decryption not enabled, can't decrypt"
    elif [ ! -e "$NETSIMDIR/encrypt/$_KEYNAME.privkey.pem" ]; then
        stream "Archive content private key for '$_KEYNAME' authority is missing, can't decrypt"
    else
        openssl pkeyutl -decrypt -in "$1" -inkey "$NETSIMDIR/encrypt/$_KEYNAME.privkey.pem" -out "${1%.*}" 2>&1 | _stream_pipe;
    fi
}

function _genkey {
    rm -f "encrypt/key.bin" "encrypt/key.bin.$ENCRYPT"
    if ! openssl rand -base64 32 > encrypt/key.bin; then
        stream "Failed to create encryption key"
        return 1
    fi
    _pub_encrypt encrypt/key.bin
    if [ ! -e "encrypt/key.bin.$ENCRYPT" ]; then
        stream "Failed to encrypt symetric encryption key for sharing"
        return 1
    fi
}

function _backup {
    NAME="${NETSIMDIR##*/}"
    stream "Preparing backup..."
    rm -f "$NAME.zip"
    ARCHIVE="$PWD/$NAME.zip"
    (
        cd "$NETSIMDIR"
        case "$1" in
            devices)    FILES=device-* ;;
            templates)  FILES=templates ;;
            *)          FILES="device-* templates" ;;
        esac
        unset _EXCLUDE
        if [ "$ENCRYPT" ]; then
            stream "Encryption is enabled using '$ENCRYPT' authority"
            if ! _genkey "$ENCRYPT"; then
                stream "Failed to create archive content encryption key, skipping backup"
                return 1
            fi
            _EXCLUDE="encrypt/key.bin"
            for folder in $FILES
            do
                case "$folder" in
                    device-*)
                        _FILE=$folder/*.snmprec
                        ;;
                    templates)
                        _FILE=$folder/*/*.snmprec
                        ;;
                esac
                for file in $_FILE
                do
                    # Skil well-known sample files
                    case "$file" in
                        templates/sample[34]/*)
                            continue
                            ;;
                    esac
                    if ! gzip -9cn $file >$file.gz; then
                        stream "Failed to compress '$file', skipping"
                        continue
                    fi
                    if ! openssl enc -aes-256-cbc -salt -pbkdf2 -in $file.gz -out $file.gz.$ENCRYPT -pass file:encrypt/key.bin; then
                        stream "Failed to encrypt '$file.gz', skipping"
                        rm -f $file.gz
                        continue
                    fi
                    sha256sum $file >$file.sha256 2>&1 | _stream_pipe
                    _pub_encrypt $file.sha256
                    rm -f $file.gz $file.sha256
                    _EXCLUDE="$_EXCLUDE $file"
                done
            done
            FILES="$FILES encrypt/key.bin.$ENCRYPT"
        fi
        if ! zip -qDr "$ARCHIVE" $FILES -x device-\*/cache/\*\* templates/sample{3,4}/\*\* $_EXCLUDE 2>&1 | _stream_pipe ; then
            stream "Failed to create backup"
        else
            stream "Backup file: $ARCHIVE"
        fi
        # Remove any encrypted file
        if [ "$ENCRYPT" ]; then
            rm -f encrypt/key.bin* device-*/*.$ENCRYPT templates/*/*.$ENCRYPT
        fi
    )
}

function _restore {
    if (( STARTED )); then
        stream "Netsim still started, stop it before doing a restore"
    else
        PATTERN=
        while [ -n "$1" ]
        do
            FILE="$1"
            [ "${FILE:0:1}" != "/" ] && FILE="$PWD/$FILE"
            if [ -e "$FILE" ]; then
                stream "Restoring '$FILE' in current netsim environment"
                (
                    cd "$NETSIMDIR"
                    if ! unzip -o "$FILE" $PATTERN 2>&1 | _stream_pipe ; then
                        stream "Failed to restore backup"
                    else
                        stream "Restored content from $FILE"
                    fi
                )
            elif [ "$FILE" == "templates" ]; then
                PATTERN="templates/\\*"
            else
                stream "Skipping not existing file: $FILE"
            fi
            shift
        done
        # Decrypt any encrypted file
        for keyfile in "$NETSIMDIR"/encrypt/key.bin.*
        do
            KEYNAME="${keyfile##$NETSIMDIR/encrypt/key.bin.}"
            [ "$KEYNAME" == '*' ] && break
            if [ -e "$NETSIMDIR/encrypt/$KEYNAME.pubkey.pem" ]; then
                _pub_decrypt "$keyfile"
                rm -f "$keyfile"
                for file in "$NETSIMDIR"/*/*.gz.$KEYNAME "$NETSIMDIR"/*/*/*.gz.$KEYNAME
                do
                    [ -e "$file" ] || continue
                    FILE="${file%.gz.$KEYNAME}"
                    if ! openssl enc -aes-256-cbc -d -pbkdf2 -in "$file" -out "$FILE.gz" -pass file:"$NETSIMDIR/encrypt/key.bin"; then
                        stream "Failed to decrypt '${file#$NETSIMDIR/}', skipping"
                        rm -f "$file" "$FILE.sha256.$KEYNAME"
                        continue
                    fi
                    rm -f "$file"
                    if ! gunzip -f "$FILE.gz"; then
                        stream "Failed to uncompress '${FILE#$NETSIMDIR/}', skipping"
                        rm -f "$FILE.gz" "$FILE.sha256.$KEYNAME"
                        continue
                    fi
                    _pub_decrypt "$FILE.sha256.$KEYNAME"
                    rm -f "$FILE.sha256.$KEYNAME"
                    if [ -e "$FILE.sha256" ]; then
                        INTEGRITY=$( cd "$NETSIMDIR" ; cat "${FILE#$NETSIMDIR/}.sha256" | sha256sum -c >/dev/null 2>&1 || echo failed)
                        rm -f "$FILE.sha256"
                        if [ "$INTEGRITY" == "failed" ]; then
                            stream "'${FILE#$NETSIMDIR/}' integrity check failure, removing"
                            rm -f "$FILE"
                            continue
                        fi
                    fi
                    stream "Decrypted ${FILE#$NETSIMDIR/} with '$KEYNAME' authority"
                done
            else
                stream "Can't decrypt files for '$KEYNAME' authority, removing"
                rm -vf "$NETSIMDIR"/device-*/*.$KEYNAME "$NETSIMDIR"/templates/*/*.$KEYNAME | _stream_pipe
            fi
            # Finally remove symetric encryption key when finished
            rm -f "$keyfile" "$NETSIMDIR/encrypt/key.bin"
        done
    fi
}

function _noencrypt {
    if [ -z "$ENCRYPT" ]; then
        stream "Archive content encryption still disabled"
    else
        stream "Disabling archive content encryption"
        ENCRYPT=""
    fi
}

function _encrypt {
    if ! which openssl >/dev/null; then
        stream "Openssl is required to manage archive encryption"
    elif [ -n "$1" ]; then
        BASEKEY="$1"
        if [ -e "$NETSIMDIR/encrypt/$BASEKEY.pubkey.pem" ]; then
            stream "Selecting '$BASEKEY' authority for archive content encryption"
            ENCRYPT="$BASEKEY"
            _encrypt
        else
            if [ ! -d "$NETSIMDIR/encrypt" ]; then
                if ! mkdir -p "$NETSIMDIR/encrypt" ]; then
                    stream "Failed to create '$NETSIMDIR/encrypt' folder, skipping encryption"
                    return 1
                fi
            fi
            stream "Generating '$BASEKEY' authority private key"
            if ! openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -pkeyopt rsa_keygen_pubexp:3 -out "$NETSIMDIR/encrypt/$BASEKEY.privkey.pem"; then
                stream "Failed to create private key, skipping encryption"
                return 1
            fi
            stream "Generating '$BASEKEY' authority public key"
            if ! openssl pkey -in "$NETSIMDIR/encrypt/$BASEKEY.privkey.pem" -out "$NETSIMDIR/encrypt/$BASEKEY.pubkey.pem" -pubout; then
                stream "Failed to create private key, skipping encryption"
                return 1
            fi
            _encrypt "$BASEKEY"
        fi
    elif [ -n "$ENCRYPT" ]; then
        if [ -e "$NETSIMDIR/encrypt/$ENCRYPT.pubkey.pem" ]; then
            stream "Current archive content encryption based on '$ENCRYPT' authority pubkey"
            if [ -e "$NETSIMDIR/encrypt/$ENCRYPT.pubkey.pem" ]; then
                openssl dgst -sha256 "$NETSIMDIR/encrypt/$ENCRYPT.pubkey.pem"
            fi
        else
            # ENCRYPT may have been set via environment so we need to simply initialize it
            _encrypt "$ENCRYPT"
        fi
    else
        _encrypt local
    fi
}

[ -n "$SERVER" ] && _server "$SERVER"
[ -n "$TAG" ] && _tag "$TAG"

_load_environment

# Following subcommands are one shot if given on command-line
let ONESHOT=0
case "$SUBCOMMAND" in
    import|walk|templates|devices|setup|ip|delete|reset|backup|restore|help)
        let ONESHOT=1
        case "$SUBCOMMAND" in
            import|walk) _setup_environment ;;
        esac
        ;;
esac

[ "$ONESHOT" == "0" -o ! -x snmpsim-record-commands ] && 

# Cleanup console only if we will handle a subcommand prompt
if (( ONESHOT == 0 )); then
    _setup_environment
    _ip
    tput -S <<TPUT
        clear
        csr 0 $((LINES-1))
        cup $((LINES-1)) 0
TPUT
fi

while true
do
    case "$SUBCOMMAND" in
        start)       _start ;;
        stop)        _stop ;;
        reload)      _reload_conf ;;
        debug)       _debug $ARGS ;;
        debug2)      _debug 2 ;;
        info)        _debug 0 ;;
        server)      _server $ARGS ;;
        tag)         _tag $ARGS ;;
        port)        _port $ARGS ;;
        run)         _run ;;
        inventory)   _inventory 1 ;;
        noinventory) _inventory 0 ;;
        sudo|nosudo) _sudo "$SUBCOMMAND" ;;
        sys|nosys)   _system "$SUBCOMMAND" ;;
        import)      _import $ARGS ;;
        walk)        _walk $ARGS ;;
        templates)   _templates ;;
        devices)     _devices ;;
        setup)       _setup $ARGS ;;
        ip*)         _ip ${ARGS:=${SUBCOMMAND#ip}} ;;
        delete)      _delete $ARGS ;;
        reset)       _reset ;;
        backup)      _backup $ARGS ;;
        restore)     _restore $ARGS ;;
        encrypt)     _encrypt $ARGS ;;
        noencrypt)   _noencrypt ;;
        cleanup)     _cleanup && break ;;
        quit)        (( STARTED )) && _stop ; break ;;
        help)        cat <<ONLINE_HELP
Netsim supported sub-commands:
 - start|stop      Start or stop network simulator
 - run             Force GLPI Agent to run tasks
 - reload          Reload GLPI Agent configuration
 - debug [0|1|2]   Set GLPI Agent debug level to 0, 1 or 2
 - debug2          Set GLPI Agent debug level to 2
 - info            Reset GLPI Agent debug level to 0
 - server URL      Set URL as GLPI Agent server target
 - tag TAG         Set TAG as GLPI Agent server tag
 - port PORT       Set PORT as GLPI Agent httpd port
 - inventory       Enable inventory task in GLPI Agent (enabled by default)
 - noinventory     Disable inventory task in GLPI Agent
 - sudo            Use sudo to start GLPI Agent and snmp agents (enabled by default)
 - nosudo          Don't use sudo to start GLPI Agent and snmp agents
 - sys             Use GLPI Agent installed in the system (disabled by default)
 - nosys           Use GLPI Agent from the current repository folder
 - quit            Quit
 - devices         List setup emulated devices
 - delete INDEX    Delete a device by INDEX
 - reset           Fully reset network simulation including agent deviceid
 - cleanup         Completely remove simulation environment and quit
 - setup NAME      Setup new device with the given template name
 - templates       List names of supported devices templates
 - import WALK     Setup new template from a walk file
 - walk [IP]       Make a walk on a network device to create a new template
 - ip [(+|-)NN|IP] Show/set ip for next setup device or increment/decrement it by NN
 - backup [TYPE]   Backup current netsim devices and templates in a zip archive
                   Set TYPE to "devices" or "templates" to limit the backup
 - restore ZIPs    Restore given zip archive in the current netsim environment
                   To restore templates only, use "templates" keyword before ZIP
 - encrypt [NAME]  Setup archive content encryption or select encryption authority
 - noencrypt       Disable archive content encryption
ONLINE_HELP
                ;;
        [ascii]*)    stream "Unsupported sub-command: $SUBCOMMAND $ARGS" ;;
    esac

    # Saving netsim environment
    cat >"$NETSIMDIR/env" <<ENV
SUDO=$SUDO
SYSTEM_AGENT=$SYSTEM
IP=$IP
AGENTPORT=$AGENTPORT
SNMPPORT=$SNMPPORT
SERVER=$SERVER
TAG=$TAG
DEBUG=$DEBUG
COMMUNITY=$COMMUNITY
ENCRYPT=$ENCRYPT
ENV

    # Leave here for one shot subcommands
    (( ONESHOT )) && break

    if [ "$SUBCOMMAND" != "help" ]; then
        echo -e "\n> Supported sub-command: start, run, stop, reload, import, walk, setup, templates, devices, delete, backup, reset, cleanup, debug, debug2, info, server, tag, port, quit, [no]sudo, [no]sys, ip, help"
    fi
    read -p "> " SUBCOMMAND ARGS
done
