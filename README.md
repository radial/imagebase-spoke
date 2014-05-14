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
