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
* OpenSSH-server (1:6.6p1-2ubuntu2)
    * By default, root login is disabled for anything other then public-key
    * Set your GitHub username with `ENV GH_USER` in your Spoke Dockerfile to
      automatically insert your public keys from GitHub into your container
      using `ssh-import-id` if you want to be able to SSH into your container.
    * **NOTE:** This is "secure" in that use of public keys are always secure,
      but it is not the wisest strategy to use the same key-pair for multiple
      venues (server cluster, public website, etc.). More robust key management
      is a feature for a future date. For now, this suffices for protypting and
      development on small clusters.

This image is not meant to be run by itself but is instead intended as a base
image with which your Spoke containers are started `FROM`. Supervisor is
installed here to make sure that all contents of the actual Spoke container
Dockerfile are for the application itself; not the topology management.

Any Spoke container run from this base needs to have certain design principals.
Check out the documentation [here](https://github.com/radial/docs) for more
details.
