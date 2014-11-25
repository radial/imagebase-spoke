# Dockerfile for Spoke-Base

This repository creates a Docker container with a fully featured operating
system using the [distribution of choice](https://github.com/radial/core-distro)
for the Radial project's Spoke (application) containers.

In addition to the base operating system, and with the "Universe" and
"Multiverse" repositories enabled, it has the additional following software:

* [Supervisor 3.0b2-1](http://supervisord.org)
    * Easily create a foreground process to keep your container alive.
    * Start/Restart processes automatically (as dictated in each programs '.ini'
      file.
    * Redirect STDOUT and manage logs accordingly

This image is not meant to be run by itself but is instead intended as a base
image with which your Spoke containers are started `FROM`. Supervisor is
installed here to make sure that all contents of the actual Spoke container
Dockerfile are for the application itself; not the topology management.

Any Spoke container run from this base needs to have certain design principals.
Check out the documentation [here](https://github.com/radial/docs) for more
details.

## Tunables

Tunable environment variables; modify at runtime. Italics are defaults.

  - **$SPOKE_CMD**: [_nothing_] Allows user to set a command (usually in the
    dockerfile) that can enable the resulting Spoke container to take arguments
    to the `docker run -it some/image` command. When this is set, and arguments
    are present, this value will behave like the ENTRYPOINT directive in the
    dockerfile and any arguments will be passed to it. Regardless of being set
    or not, however, if no arguments are given, the Spoke container will start
    Supervisord normally along with all the checks that go along with it.
  - **$SPOKE_DETACH_MODE**: [True|_False_] Bypass hub/wheel checks and run Spoke
    anyway. Useful for debugging and in cases of extreme need for portability
    for the Spoke container, or, if it truly is a stand-alone container without
    any need for configuration via the typical hub method of configuration
    management. Your Spoke needs to specifically be created for such a purpose.
    - For **SPOKE_DETACH_MODE** only:
        - **$SUPERVISOR_REPO**:
        [_"https://github.com/radial/config-supervisor.git"_] 
        - **$SUPERVISOR_BRANCH**: [_"master"_]
        - **$WHEEL_REPO**: [_nothing_]
        - **$WHEEL_BRANCH**: [_"config"_]
