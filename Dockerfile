# Dockerfile for Spoke-Base

# Updates are done here to allow for the Spoke container to be only focused on
# the application code.

FROM            radial/distro:us-west-1
MAINTAINER      Brian Clements <radial@brianclements.net>

# Keep upstart from throwing errors
RUN             dpkg-divert --local --rename --add /sbin/initctl &&\
                ln -sf /bin/true /sbin/initctl

# Update system (usually very small), install default packages
ENV             DEBIAN_FRONTEND noninteractive
RUN             apt-get -q update &&\
                apt-get -qyV upgrade &&\
                apt-get clean &&\
                rm -rf /var/lib/apt/lists/*

# Add our universal Spoke init script
COPY            /SPOKE /SPOKE

# Not meant for running by itself.
ENTRYPOINT      /bin/false

# Update System again before actual build
ONBUILD ENV     DEBIAN_FRONTEND noninteractive
ONBUILD RUN     apt-get -q update &&\
                apt-get -qyV upgrade &&\
                apt-get clean &&\
                rm -rf /var/lib/apt/lists/*

# By default, the contents of '/data' is owned by root (set in the
# radial/hub-base Dockerfile) with 755 folder permissions. If this folder, or
# any of it's subfolders, need to have different permissions or ownership, it
# must be done in the entrypoint.sh script for that spokes application. Since
# '/data' is a volume container, this cannot be done in any of the Dockerfiles
# themselves. Remember to actually run your application as the appropriate
# user. 

# On the resulting Spoke container, this init script will take care of
# launching our Spokes "entrypoint.sh" script, passing it signals, and sending
# std{out|err} to either log files, the docker daemon, or both.
ONBUILD ENTRYPOINT ["/SPOKE"]
