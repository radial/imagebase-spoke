# Dockerfile for Spoke-Base

This repository creates a Docker container with a fully featured operating
system using the [distribution of choice](https://github.com/radial/core-distro)
for the Radial project's Spoke (application) containers.

This image can be run by itself, but is intended to be a base image with which
your Spoke containers are started `FROM`. In addition to the base operating
system, and with the "Universe" and "Multiverse" repositories enabled, a helper
setup script is installed here ("SPOKE") to make sure that all contents of the
actual Spoke container Dockerfile are for the application itself; not the
topology management. It can gracefully manage a container startup in a Radial
wheel environment (check for hub container readiness, download Wheel
configuration etc.) and then hand off control to the `entrypoint.sh` script
you've created in your Spoke container.

Any Spoke container that is run from this base needs to have certain design
principals. Check out the documentation [here](https://github.com/radial/docs)
for more details.

## Logging

One important note is that the `SPOKE` helper script will send STDOUT and STDERR
to both the docker daemon so that one can use `docker logs` or other log driver
plugins as well as to files in `/log/${HOSTNAME}/${SPOKE_NAME}/` so that one can
harvest the logs directly with other applications running in other containers if
desired. The application running in the Spoke container should always write to
STDOUT and STDERR to maintain this dual accessibility of log files.

## Tunables

Tunable environment variables; modify at runtime. Italics are defaults.

  - **$SPOKE_CMD**: [_nothing_] Allows user to set a command (usually in the
    dockerfile) that can enable the resulting Spoke container to take arguments
    to the `docker run -it some/image` command. When this is set, and arguments
    are present, this value will behave like the ENTRYPOINT directive in the
    dockerfile and any arguments will be passed to it. Regardless of being set
    or not, however, if no arguments are given, the Spoke container will start
    the script `/entrypoint.sh` normally along with all the checks that go along
    with it.
  - **$SPOKE_DETACH_MODE**: [True|_False_] Bypass hub/wheel checks and run Spoke
    anyway. Useful for debugging and in cases of extreme need for portability
    for the Spoke container, or, if it truly is a stand-alone container without
    any need for configuration via the typical hub method of configuration
    management. Your Spoke needs to specifically be created for such a purpose.
    - For **SPOKE_DETACH_MODE** only:
        - **$WHEEL_REPO**: [_nothing_]
        - **$WHEEL_BRANCH**: [_"config"_]
