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
ENV DEBIAN_FRONTEND noninteractive
RUN         apt-get -q update && apt-get -qqyV install \
                supervisor &&\
            apt-get clean
RUN         env --unset=DEBIAN_FRONTEND

# Not meant for running by itself.
CMD         ["/bin/false"]
