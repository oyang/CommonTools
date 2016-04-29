# Packer template for CentOS
Packer template for creating CentOS Vagrant boxes

### Overview
This is a cloned and modified version from https://github.com/boxcutter/centos

## Building the Vagrant boxes with Packer
To build all the boxes, you will need [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

We make use of JSON files containing user variables to build specific versions of Ubuntu.
You tell `packer` to use a specific user variable file via the `-var-file=` command line
option.  This will override the default options on the core `centos.json` packer template,
which builds CentOS 6.7 by default.

For example, to build CentOS 6.7, use the following:

    $ packer build -var-file=var/centos67.json centos.jso
    
If you want to make boxes for a specific desktop virtualization platform, use the `-only`
parameter.  For example, to build CentOS 6.7 for VirtualBox:

    $ packer build -only=virtualbox-iso -var-file=var/centos67.json centos.json
