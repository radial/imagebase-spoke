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

# On the resulting Spoke container, we must:
# 1) Ensure $USER ownership for everything first
# 2) Ensure root ownership for supervisor config files
# 3) Create a unique folder for all our logs based on our container name
# 4) Start the supervisor daemon
ONBUILD ENTRYPOINT \
                chown -R $USER:$GROUP /config /data /log &&\
                chown -R root:root /config/supervisor &&\
                mkdir -p /log/$HOSTNAME &&\
                supervisord \
                    --configuration=/config/supervisor/supervisord.conf \
                    --logfile=/log/$HOSTNAME/supervisord.log
