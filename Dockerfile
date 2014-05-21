# Dockerfile for Spoke-Base
# 
# This Spoke-Base Dockerfile adds a required package for Spoke container
# management in the Radial topology. Supervisor is used as the main interface
# for `docker attach` as well as for managing the running process contained
# therein. Installation is done here to allow for the Spoke container to be only
# focused on the application code.

FROM            radial/distro
MAINTAINER      Brian Clements <radial@brianclements.net>

# Install packages
ENV             DEBIAN_FRONTEND noninteractive
RUN             apt-get -q update && apt-get -qyV install \
                    openssh-server \
                    supervisor &&\
                apt-get clean
RUN             env --unset=DEBIAN_FRONTEND

# Not meant for running by itself.
ENTRYPOINT      /bin/false

# The only mandatory ENVs in your Spoke Dockerfile are $USER and $GROUP, and
# they are set to root by default. This will make sure $USER:$GROUP ownership
# is set on your configuration files. In order to change it, you can set 'ENV
# USER' and 'ENV GROUP' at anypoint in your Spoke container Dockerfile and make
# sure to add that user and group to the system with:
#
# `RUN groupadd $GROUP`
# `RUN useradd --system -g $GROUP $USER`
#
# or add an existing user to $GROUP with:
#
# `RUN usermod -a -G $GROUP $USER`
#
# or something similar. To actually run your application as this user however,
# you must declare such in your Supervisor .ini file for this program located
# in '/config/supervisor/conf.d'. Supervisor itself will be run as root
# regardless.
ONBUILD ENV     USER root
ONBUILD ENV     GROUP root

# SSH
# To enable SSH into this container, supply your GitHub username for $GH_USER
# with `ENV GH_USER` in your Spoke Dockerfile and the same public keys used for
# GitHub will be inserted into your container. This is 'secure' in that use of
# public keys are always secure, but it is not the wisest strategy to use the
# same key-pair for multiple venues (server cluster, public website, etc.). More
# robust key management is a feature for a future date. For now, this suffices
# for protypting and development on small clusters.
#
# For the security minded, the default '/__NULL__/' value fails the syntax test
# in `ssh-import-id` and never reaches the github API. This is safer then
# sending an "unlikely" value to the API and hoping it doesn't match anything.
ONBUILD ENV     GH_USER /__NULL__/
ONBUILD RUN     mkdir -p /var/run/sshd

# On the resulting Spoke container, we must:
# 1) Try to grab SSH public keys from GitHub if $GH_USER is set
# 2) Ensure $USER ownership for everything first
# 3) Ensure root ownership for supervisor config files
# 4) Create a unique folder for all our logs based on our container name
# 5) Start the supervisor daemon
ONBUILD ENTRYPOINT \
                ssh-import-id --output /root/.ssh/authorized_keys gh:$GH_USER; \
                chown -R $USER:$GROUP /config /data /log &&\
                chown -R root:root /config/supervisor &&\
                mkdir -p /log/$HOSTNAME &&\
                supervisord \
                    --configuration=/config/supervisor/supervisord.conf \
                    --logfile=/log/$HOSTNAME/supervisord.log
