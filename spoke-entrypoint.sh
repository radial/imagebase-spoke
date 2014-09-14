#!/bin/bash
set -e

APP_GROUP="$SPOKE_NAME-group"

if [ -z $SPOKE_NAME ]; then
    echo "Error: SPOKE_NAME variable not set in Dockerfile. Supervisor doesn't know what to start."
    exit 1
fi

# Wait until the Hub container is done loading all configuration.
echo "Spoke \"$SPOKE_NAME\" is waiting for Hub container to load..."
while [ -d /run/hub.lock ]; do
    sleep 1s
done
echo "Hub container loaded. Continuing to load Spoke \"$SPOKE_NAME\"."

if [ ! -e /tmp/first_run ]; then
    touch /tmp/first_run

    # Import public keys from github
    if [ ! $GH_USER = "/__NULL__/" ]; then
        ssh-import-id --output /root/.ssh/authorized_keys gh:$GH_USER
    fi

    # Make unique directory for logs
    mkdir -p /log/$HOSTNAME
fi

# The following programs need to be run after supervisor starts, however,
# we need to run supervisor last because of `exec` in this script. So we run
# them with a delay until after supervisor claims PID 1 through exec.

# Start SSHD if GH_USER is set.
if [ ! $GH_USER = "/__NULL__/" ]; then
    /bin/sh -c "while [ ! -e /var/local/run/supervisord.pid ]; do sleep 1s; done &&
                supervisorctl -s unix:///var/local/run/supervisor.sock start sshd" &
fi


# Start this spoke's program group
    /bin/sh -c "while [ ! -e /var/local/run/supervisord.pid ]; do sleep 1s; done &&
                supervisorctl -s unix:///var/local/run/supervisor.sock start $APP_GROUP:*" &

# Copy errors to main log for easy debugging with `docker logs` if errors occur
# preventing application startup. No need to include normal output here
# because a real log management solution should be in place for that.
/bin/sh -c "while [ "$(ls -A /log/$HOSTNAME)" = "" ]; do sleep 1s; done &&
            tail --follow=name -c +0 /log/$HOSTNAME/*_stderr.log |
            tee -a /log/$HOSTNAME/supervisord.log" &

exec supervisord \
    --configuration=/config/supervisor/supervisord.conf \
    --logfile=/log/$HOSTNAME/supervisord.log
