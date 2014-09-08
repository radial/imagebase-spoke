# Dockerfile for Spoke-Base
# 
# This Spoke-Base Dockerfile adds a required package for Spoke container
# management in the Radial topology. Supervisor is used as the main interface
# for `docker attach` as well as for managing the running process contained
# therein. Installation is done here to allow for the Spoke container to be only
# focused on the application code.

FROM            radial/distro:us-west-1
MAINTAINER      Brian Clements <radial@brianclements.net>

# Update system (usually very small), install default packages
ENV             DEBIAN_FRONTEND noninteractive
RUN             apt-get -q update &&\
                apt-get -qyV upgrade &&\
                apt-get -qyV install \
                    openssh-server \
                    supervisor &&\
                apt-get clean &&\
                rm -rf /var/lib/apt/lists/*
RUN             env --unset=DEBIAN_FRONTEND

# SSH login fix. Otherwise user is kicked off after login
RUN             sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Create unique Spoke run directory. /var/run and /run are shared as volumes 
# for inter-spoke communication via sockets.
RUN             mkdir -m 777 /var/local/run &&\
                chown root:root /var/local/run

# Add our universal Spoke ENTRYPOINT
COPY            /spoke-entrypoint.sh /spoke-entrypoint.sh

# Not meant for running by itself.
ENTRYPOINT      /bin/false

# Update System again before actual build
ONBUILD ENV     DEBIAN_FRONTEND noninteractive
ONBUILD RUN     apt-get -q update &&\
                apt-get -qyV upgrade &&\
                apt-get clean &&\
                rm -rf /var/lib/apt/lists/*
ONBUILD RUN     env --unset=DEBIAN_FRONTEND

# By default, the contents of '/data' is owned by root (set in the
# radial/hub-base Dockerfile) with 755 folder permissions. If this folder, or
# any of it's subfolders, need to have different permissions or ownership, it
# must be done in the entrypoint.sh script for that spokes application (the one
# started in the Supervisor .ini file). Since '/data' is a volume container,
# this cannot be done in any of the Dockerfiles themselves. Remember to
# actually run your application as the appropriate user. You can set this
# information in your Supervisor .ini file for this program located in
# '/config/supervisor/conf.d'.
# Supervisor itself will be run as root regardless.

# SSH
# Replace the default host keys with a new set on every build.
ONBUILD RUN     rm /etc/ssh/ssh_host_* &&\
                dpkg-reconfigure openssh-server

# To enable SSH into this container, supply your GitHub username for $GH_USER
# with `ENV GH_USER` in your Spoke Dockerfile and the same public keys used for
# GitHub will be inserted into your container. This is 'secure' in that use of
# public keys are always secure, but it is not the wisest strategy to use the
# same key-pair for multiple venues (server cluster, public website, etc.). More
# robust key management is a feature for a future date. For now, this suffices
# for prototyping and development on small clusters.
#
# For the security minded, the default '/__NULL__/' value fails the syntax test
# in `ssh-import-id` and never reaches the github API. This is safer then
# sending an "unlikely" value to the API and hoping it doesn't match anything.
ONBUILD ENV     GH_USER /__NULL__/
ONBUILD RUN     mkdir -p /var/run/sshd

# On the resulting Spoke container, this ENTRYPOINT script will:
# 1) Try to grab SSH public keys from GitHub if $GH_USER is set
# 2) Create a unique folder for all our logs based on our container name
# 3) Start the supervisor daemon
# 4) Start this Spoke's main app group and
# 5) Show the combined output of the app and Supervisor
ONBUILD ENTRYPOINT ["/spoke-entrypoint.sh"]
