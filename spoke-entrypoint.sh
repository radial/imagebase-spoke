#!/bin/bash
set -e

# Tunable variables
SPOKE_DETACH_MODE=${SPOKE_DETACH_MODE:-"False"}
# For special-case server stand alone mode; will run without a hub container.
# This mode is fussy and only for special cases that truly need to be run
# as an individual container.
WHEEL_REPO=${WHEEL_REPO:-""}
WHEEL_BRANCH=${WHEEL_BRANCH:-"config"}
SPOKE_CMD=${SPOKE_CMD:-""}

pull_wheel_config() {
    remoteName=$(date | md5sum | head -c10)
    git remote add ${remoteName} ${WHEEL_REPO}
    git pull --no-edit ${remoteName} ${WHEEL_BRANCH}
}

apply_permissions() {
    # Set file and folder permissions for all configuration and uploaded
    # files.

    do_apply() {
        if [ "$(find "$1" -type d -not -path "*/.git*")" ]; then
            find "$1" -type d -not -path "*/.git*" -print0 | xargs -0 chmod 755
            if [ "$(find "$1" -type f -not -path "*/.git*")" ]; then
                find "$1" -type f -not -path "*/.git*" -print0 | xargs -0 chmod 644
            fi
            echo "...file permissions successfully applied to $1."
        fi
    }

    if [ -d /config ]; then
        do_apply /config
    fi
    if [ -d /data ]; then
        do_apply /data
    fi
    if [ -d /log ]; then
        do_apply /log
    fi
}

run_spoke_checks() {
    if [ "$SPOKE_DETACH_MODE" = "False" ]; then
        if [ ! -d /config ]; then
            echo "Error: No Hub container detected."
            exit 1
        fi
        # Wait until the Hub container is done loading all configuration.
        echo "Spoke \"$SPOKE_NAME\" is waiting for Hub container to load..."
        while [ -d /run/hub.lock ]; do
            sleep 1s
        done
        echo "Hub container loaded. Continuing to load Spoke \"$SPOKE_NAME\"."
    elif [ "$WHEEL_REPO" = "" ]; then
            echo "Warning: \"Spoke-detach\" mode is enabled, but the \`\$WHEEL_REPO\` variable is not set. This Spoke will not pull any configuration."
    else
        if [ ! $(which git) ]; then
            echo "git is required for \"Spoke-detach\" mode. Please install it in your Spoke Dockerfile."
            exit 1
        fi
        if [ -d /config ]; then
            echo "\"Spoke-detach\" mode cannot run with \`--volumes-from\` any hub containers."
            exit 1
        fi
    fi
}

do_first_run_tasks() {
    # Setup configuration in spoke-detach mode only
    if [ "$SPOKE_DETACH_MODE" = "True" ]; then
        mkdir -p /data /log
        cd /config
        if [ "$WHEEL_REPO" != "" ]; then
            pull_wheel_config
        fi
        apply_permissions 
    fi

    # Make unique directory for logs
    mkdir -p /log/$HOSTNAME/$SPOKE_NAME
}

start_normal() {
    # we use tee to throw all entrypoint.sh output to files as well as
    # to std{out|in} so that docker can have access.
    exec > >(tee -ai /log/${HOSTNAME}/${SPOKE_NAME}/${SPOKE_NAME}_stdout.log)
    exec 2> >(tee -ai /log/${HOSTNAME}/${SPOKE_NAME}/${SPOKE_NAME}_stderr.log)
    exec /entrypoint.sh
}

if [ $# -eq 0 ]; then
    if [ ! -e /tmp/first_run ]; then
        touch /tmp/first_run

        run_spoke_checks
        do_first_run_tasks
    fi

    start_normal

elif [ "$SPOKE_CMD" != "" ]; then
    /bin/sh -c "exec ${SPOKE_CMD} $(echo "$@")"
else
    /bin/sh -c "exec $(echo "$@")"
fi
