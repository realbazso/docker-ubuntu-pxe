#!/bin/bash
#
# Usage: create-install-network.sh <bridge name> <host ip in install net> <netmask> 
# Be careful! Under development, no error handling yet!!!
#
# The script creates a permanent host only bridged network and configures it for kvm.

# printf "#------Host Only network for KVM------------\nauto $1\niface $1 inet static\n\taddress $2\n\tnetmask $3\n\tpre-up brctl addbr $1\n\tpost-down brctl delbr $1\n#-end of-----Host Only network for KVM------\n" >> /etc/network/interfaces

# ifup $1

echo "<network> <name>k-$1</name> <bridge name='$1' /> </network>" > /tmp/create-install-network.tmp

virsh net-define /tmp/create-install-network.tmp
virsh net-start k-$1
virsh net-autostart k-$1

