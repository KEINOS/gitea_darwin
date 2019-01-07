#!/usr/bin/env bash

## Get error on pipe fail too
set -e -o pipefail

# Basic Info settings
# ------------------------------------------------------------------------------

## Latest release info in JSON
URL_API='https://api.github.com/repos/go-gitea/gitea/releases/latest'

## Basic user settings
NAME_BIN='gitea'     # Name of binary at last
NAME_HOST=`hostname` # Local host name
NAME_OS='darwin'     # macOS is darwin. See URL_API above for other OS
NAME_CPU='amd64'     # 64bit Mac
NAME_EXT='.xz'       # Files related to XZ. Such as .xz, .xz.asc, .xz.sha256

## Basic application settings (Do NOT change this)
PATH_DIR_APPINI='custom/conf'
NAME_APPINI='app.ini'
PATH_FILE_APPINI="${PATH_DIR_APPINI}/${NAME_APPINI}"


# Basic functions
# ------------------------------------------------------------------------------

function getPortUsed() {
    # この取得処理が一番重いので変数に入れて使い回すために用意
    echo `lsof -i -P | grep -i "tcp" | sed 's/\[.*\]/IP/' \
                   | sed 's/:/ /' | sed 's/->/ /'| awk -F' ' '{print $10}' \
                   | awk '!a[$0]++'`
}

function getPortRandom() {

    # 使用中のポート一覧がセットされていなければ関数内で取得
    if [ -z ${port_list+x} ]; then
        port_list=`getPortUsed`
    fi

    # 検索ポートの範囲指定（デフォルト範囲）
    port_min=${1:-1}
    port_max=${2:-65535}

    # 希望するポートがセットされていない場合や範囲外の場合は初期化
    if [ -z "$port" ] || [ $port_min -gt $port ] || [ $port_max -lt $port ]; then
        port=`jot -w %i -r 1 $port_min $((port_max+1))`
    fi
    
    port=$((port+0)) #文字列の数字を数値に変換
    
    while :
    do
        port_collide=0

        # 使用中のポート一覧と $port を比較
        for port_used in $port_list
        do
            if [ "$port" = "$port_used" ]; then
                port_collide=1 # 使用中のポートと同じ
                break          # 処理を抜けてランダム番号を再取得
            fi
        done

        # 現在の $port が使用中ポートと重ならない場合は処理を抜ける
        if [ $port_collide -eq 0 ]; then
            break
        fi

        # ランダムな番号を取得
        port=`jot -w %i -r 1 $port_min $((port_max+1))`
    done

    echo $port
}

function isBinAlreadyExists() {
    ./$NAME_BIN --version > /dev/null 2>&1
    echo $?
}

# Main
# ------------------------------------------------------------------------------

## Checking existing binay 
echo -n '- Checking existing binary: '
IS_UPDATE='no'
if [ `isBinAlreadyExists` -eq 0 ] ; then
    IS_UPDATE='yes'
fi
if [ $IS_UPDATE = 'yes' ] ; then
    echo 'binary found ... updating'
    echo -n -e "- Current version: \n\t"
    ./$NAME_BIN --version
    mv ./$NAME_BIN ./$NAME_BIN.old
else
    echo 'no binary found ... installing newly'
fi


## Get JSON and fetch *amd64 archive and the hash digest list from it
echo -n '- Fetching latest release: '
#CMD=`curl -s "${URL_API}" | jq -r '.assets[] | .browser_download_url'| grep ${NAME_OS} | grep ${NAME_CPU}.xz | sed -e 's/http/ -O http/'`
URLS=`curl -s "${URL_API}" | grep 'browser_download_url' | grep ${NAME_OS} | grep ${NAME_CPU}.xz | sed -E 's/^.*"([^"]+)".*/\1/' | sed 's/http/ -O http/'`
if [ $? -gt 0 ]; then
    echo '* Error while fetching releases.'
    exit $LINENO
fi
echo 'OK'


## Download files
echo '- Downloading files: '
curl -L ${URLS}
if [ $? -gt 0 ]; then
    echo '* Error while downloading files.'
    exit $LINENO
fi
echo ''


## Compare hash digest
echo -n '- Comparing checksum: '
shasum -a 256 -c *.sha256
if [ $? -gt 0 ]; then
    echo '* Error while comparing checksum files.'
    exit $LINENO
fi


## De-compress archive
echo -n '- Decompressing XZ archive: '
xz -d *.xz
if [ $? -gt 0 ]; then
    echo '* Error while decompressing archive file.'
    exit $LINENO
fi
echo 'OK'


## Removing un-necessary files
echo -n '- Removing un-necessary files: '
rm *.xz*
if [ $? -gt 0 ]; then
    echo '* Error while removing files.'
    exit $LINENO
fi
echo 'OK'


## Renaming binary file
echo -n '- Renaming binary file: '
mv *-${NAME_CPU} ${NAME_BIN}
if [ $? -gt 0 ]; then
    echo '* Error while renaming binary.'
    exit $LINENO
fi
echo 'OK'


## Changing file mode of the binary
echo -n '- Changing mode of the binary as executable: '
chmod +x ${NAME_BIN}
if [ $? -gt 0 ]; then
    echo '* Error while changing mode.'
    exit $LINENO
fi
echo 'OK'


## Display installed path
echo -n -e "- Installed path: \n\t"
pwd
if [ $? -gt 0 ]; then
    echo '* Error while showing path.'
    exit $LINENO
fi


## Display version info of the binary
echo -n -e "- Installed version: \n\t"
./$NAME_BIN --version
if [ $? -gt 0 ]; then
    echo '* Error while executing binary.'
    exit $LINENO
fi


## Exit if it's an update
if [ $IS_UPDATE = 'yes' ] ; then
    echo 'Updating finished.'
    exit 0
fi


## Done message if not Mac
if [ "$(uname)" != 'Darwin' ]; then
    echo "* ${NAME_BIN} installed successfuly."
    exit 0
fi


# custom/conf/app.ini
# ------------------------------------------------------------------------------

## Creating dir for app.ini
echo -n '- Creating directory for application settings: '
mkdir -p ${PATH_DIR_APPINI}
if [ $? -gt 0 ]; then
    echo '* Error while creating directory.'
    exit $LINENO
fi
echo 'OK'

## Fetch in-use ports
echo -n '- Fetching ports in use: '
port_list=`getPortUsed`
if [ $? -gt 0 ]; then
    echo '* Error while fetching ports in use.'
    exit $LINENO
fi
echo 'OK'

## Fetch unused random ports for HTTP
echo -n '- Fetching unused ports for builtin Webserver: '
port=8080 # Preferred port number
port_http=`getPortRandom`
if [ $? -gt 0 ]; then
    echo '* Error while fetching random ports.'
    exit $LINENO
fi
echo "OK (PORT: ${port_http})"

## Fetch unused random ports for SSH
echo -n '- Fetching unused ports for builtin SSH: '
port=22 # Preferred port number
port_ssh=`getPortRandom`
if [ $? -gt 0 ]; then
    echo '* Error while fetching random ports.'
    exit $LINENO
fi
echo "OK (PORT: ${port_ssh})"

## Creating configuration file as default
## See the URL below for details:
## https://docs.gitea.io/en-us/config-cheat-sheet/
echo -n '- Creating application ini file: '
cat << _EOF_ > ${PATH_FILE_APPINI}
[server]
HTTP_PORT = ${port_http}
SSH_PORT = ${port_ssh}
ROOT_URL = http://${NAME_HOST}:${port_http}/
START_SSH_SERVER = true

[database]
DB_TYPE   = sqlite3
_EOF_

if [ $? -gt 0 ]; then
    echo '* Error while creating app.ini.'
    exit $LINENO
fi
echo 'OK'

echo -e "\n* DONE. ${NAME_BIN} installed successfuly.\n"

# Start server and launch browser to setup
# ------------------------------------------------------------------------------

echo -n "Would you like to launch the browser to setup ${NAME_BIN} now? (y/n):"

read input

input=`tr '[a-z]' '[A-Z]' <<< $input`

if [ ${input:0:1} = 'Y' ] ; then
    echo 'Starting git server ... (to stop server press control+c)'

    ## Launch browser then server
    open "http://localhost:${port_http}/" && ./${NAME_BIN} web
else
    echo ''
    echo 'Manual:'
    echo '1. Start the Git server as below:'
    echo -e "\t\`$ ./${NAME_BIN} web\`"
    echo '2. Then access below from the browser to setup:'
    echo -e "\t- From local machine: http://localhost:${port_http}/"
    echo -e "\t- From other machine: http://${NAME_HOST}:${port_http}/"
fi

exit 0

