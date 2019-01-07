#!/bin/bash

# 
#  This script will start gitea server in background.
#  

NAME_BIN_GITEA='gitea'
CMD_RUN_BIN="${NAME_BIN_GITEA} web"
PID_GITEA=$(pgrep -fo "$CMD_RUN_BIN")
PATH_DIR_SCRIPT=$(cd $(dirname $0); pwd)

function getPathFileBin() {

    which $NAME_BIN_GITEA > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        echo `which $NAME_BIN_GITEA`
        return 0
    fi

    ./$NAME_BIN_GITEA --version > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        echo ./$NAME_BIN_GITEA
        return 0
    fi

    $PATH_DIR_SCRIPT/$NAME_BIN_GITEA --version > /dev/null 2>&1
    if [ $? -eq 0 ] ; then
        echo $PATH_DIR_SCRIPT/$NAME_BIN_GITEA
        return 0
    fi

    echo 'No Gitea bin found.'
    exit $LINENO
}

function getPathFileLog() {
    PATH_FILE_BIN=`getPathFileBin`
    PATH_DIR_BIN=$(dirname $PATH_FILE_BIN)
    echo $PATH_DIR_BIN/log/gitea.log
}

if [ -n "$PID_GITEA" ]; then
    echo "Gitea server is already running. (PID: ${PID_GITEA})" >&2
    PATH_FILE_LOG=`getPathFileLog` && \
    cat $PATH_FILE_LOG | grep -o "Listen: [0-9htps:\/\.]*" | tail -1
    exit $?
fi

echo -n 'Starting Gitea server ... '

PATH_DIR_BIN=$(dirname `getPathFileBin`)
cd $PATH_DIR_BIN
nohup ./$CMD_RUN_BIN > /dev/null 2>&1 &

sleep 2

PID_GITEA=$(pgrep -fo "$CMD_RUN_BIN")
if [ -n "$PID_GITEA" ]; then
    echo 'OK'
    PATH_FILE_LOG=`getPathFileLog` && \
    cat $PATH_FILE_LOG | grep -o "Listen: [0-9htps:\/\.]*" | tail -1
    exit $?
else
    echo 'Fail starting server'
    exit $LINENO
fi
