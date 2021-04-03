# Arch Linux Packer Template for MAAS

Note that this **currently does not work**. There are the following issues:

- The final tgz image isn't properly created; `output-qemu/packer-qemu` needs to be manually compressed instead.
- MAAS 2.9 fails to deploy the image with the following error:

  ```text
  start: cmd-install/stage-curthooks/builtin/cmd-curthooks: curtin command curthooks
  Running curtin builtin curthooks
  finish: cmd-install/stage-curthooks/builtin/cmd-curthooks: FAIL: curtin command curthooks
  Traceback (most recent call last):
    File "/curtin/curtin/commands/main.py", line 202, in main
      ret = args.func(args)
    File "/curtin/curtin/commands/curthooks.py", line 1891, in curthooks
      builtin_curthooks(cfg, target, state)
    File "/curtin/curtin/commands/curthooks.py", line 1686, in builtin_curthooks
      distro_info = distro.get_distroinfo(target=target)
    File "/curtin/curtin/distro.py", line 117, in get_distroinfo
      variant_name = os_release(target=target)['ID']
  KeyError: 'ID'
  'ID'
  curtin: Installation failed with exception: Unexpected error while running command.
  Command: ['curtin', 'curthooks']
  Exit code: 3
  Reason: -
  Stdout: start: cmd-install/stage-curthooks/builtin/cmd-curthooks: curtin command curthooks
          Running curtin builtin curthooks
          finish: cmd-install/stage-curthooks/builtin/cmd-curthooks: FAIL: curtin command curthooks
          Traceback (most recent call last):
            File "/curtin/curtin/commands/main.py", line 202, in main
              ret = args.func(args)
            File "/curtin/curtin/commands/curthooks.py", line 1891, in curthooks
              builtin_curthooks(cfg, target, state)
            File "/curtin/curtin/commands/curthooks.py", line 1686, in builtin_curthooks
              distro_info = distro.get_distroinfo(target=target)
            File "/curtin/curtin/distro.py", line 117, in get_distroinfo
              variant_name = os_release(target=target)['ID']
          KeyError: 'ID'
          'ID'
          
  Stderr: ''
  ```

  Arch does create */etc/os-release* properly, so it is unclear where this comes from. The installed image appears to also attempt to pull an Ubuntu kernel on boot. In other words, this is fundamentally broken right now, and I do not have time to debug.

## Introduction
The Packer template in this directory creates a Arch Linux AMD64 image for use
with MAAS.

## Prerequisites (to create the image)

* A machine running Ubuntu 18.04+ with the ability to run KVM virtual machines.
* qemu-utils
* ovmf
* [Packer.](https://www.packer.io/intro/getting-started/install.html)

## Requirements (to deploy the image)

* [MAAS](https://maas.io) 2.3+, [MAAS](https://maas.io) 2.7+ recommended
* [Curtin](https://launchpad.net/curtin) 19.3-792+

## Default user
The default username is arch

## Customizing the Image
The deployment image may be customized by modifying http/install.sh. As Arch Linux doesn't officially have an installer, see the [ArchWiki](https://wiki.archlinux.org) and the [installation guide](https://wiki.archlinux.org/index.php/Installation_guide) for more information.

## Building the image using a proxy
The Packer template downloads the CentOS net installer from the Internet. To
tell Packer to use a proxy set the HTTP_PROXY environment variable to your proxy
server. Alternatively you may redefine iso_url to a local file, set
iso_checksum_type to none to disable checksuming, and remove iso_checksum_url.

To use a proxy during the installation add the --proxy=$HTTP_PROXY flag to every
line starting with url or repo in http/centos8.ks. Alternatively you may set the
--mirrorlist values to a local mirror.

## Building an image
Your current working directory must be in packer-maas/centos8, where this file
is located. Once in packer-maas/centos8 you can generate an image with:

```
$ sudo PACKER_LOG=1 packer build archlinux.json
```

Note: archlinux.json is configured to run Packer in headless mode. Only Packer
output will be seen. If you wish to see the installation output connect to the
VNC port given in the Packer output or change the value of headless to false in
archlinux.json.

Installation is non-interactive.

## Uploading an image to MAAS
```
$ maas $PROFILE boot-resources create name='centos/8-custom' title='CentOS 8 Custom' architecture='amd64/generic' filetype='tgz' content@=centos8.tar.gz
```
