#!/bin/bash
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free  Software Foundation; either version 2 of the License, or
# (at your option)  any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301 USA.
#
#
# purpose: This script will download a fedora image and then modify it 
#          to prepare it for Digital Ocean's infrastructure. It uses 
#          Docker to hopefully guarantee the behavior is consistent across 
#          different machines.
#  author: Dusty Mabe (dusty@dustymabe.com)

set -eu 
mkdir -p /tmp/doimg/
cd /tmp/doimg

# need wget/sha256sum/unxz for this script
#   for exe in wget sha256sum unxz; do
#       if ! which $exe >/dev/null; then
#           echo "You need $exe to run this program"
#           exit 1
#       fi
#   done

docker run -i --rm --privileged -v /tmp/doimg:/tmp/doimg fedora:25 bash << 'EOF'
set -eux
WORKDIR=/workdir
TMPMNT=/workdir/tmp/mnt

# Vars for the image
XZIMGURL='https://dl.fedoraproject.org/pub/alt/atomic/stable/Fedora-Atomic-25-20170512.2/CloudImages/x86_64/images/Fedora-Atomic-25-20170512.2.x86_64.raw.xz'
XZIMG=$(basename $XZIMGURL) # Just the file name
XZIMGSUM='e4555a31e155df0323dd2d8b25f21b4d8e03e6c63bf1df31e212cae2c5e273af'
IMG=${XZIMG:0:-3}           # Pull .xz off of the end

# Create workdir and cd to it
mkdir -p $TMPMNT && cd $WORKDIR

# Get any additional rpms that we need
dnf install -y wget xz lvm2

# Get the xz image, verify, and decompress the contents
wget $XZIMGURL
imgsum=$(sha256sum $XZIMG | cut -d " " -f 1)
if [ "$imgsum" != "$XZIMGSUM" ]; then
    echo "Checksum doesn't match: $imgsum"
    exit 1
fi
unxz $XZIMG


# Discover the next available loopback device
LOOPDEV=$(losetup -f)
LOMAJOR=''

# Make the loopback device if it doesn't exist already
if [ ! -e $LOOPDEV ]; then
    LOMAJOR=${LOOPDEV#/dev/loop} # Get just the number
    mknod -m660 $LOOPDEV b 7 $LOMAJOR
fi

# Find the starting byte and the total bytes in the 2nd partition
# We only care about the 2nd partition - the first partition is /boot
PAIRS=$(partx --pairs $IMG)
eval `echo "$PAIRS" | tail -n 1 | sed 's/ /\n/g'`
STARTBYTES=$((512*START))   # 512 bytes * the number of the start sector
TOTALBYTES=$((512*SECTORS)) # 512 bytes * the number of sectors in the partition

# Loopmount the 2nd partition of the device
losetup -v --offset $STARTBYTES --sizelimit $TOTALBYTES $LOOPDEV $IMG

# Tell lvm to not depend on udev and create device nodes itself.
#sed -i 's/udev_sync = 1/udev_sync = 0/' /etc/lvm/lvm.conf
#sed -i 's/udev_rules = 1/udev_rules = 0/' /etc/lvm/lvm.conf

# Enable volume group
pvscan
vgchange -a y atomicos
vgscan --mknodes

# Mount it on $TMPMNT
mount /dev/mapper/atomicos-root $TMPMNT

# Disable NM and enable network
chroot ${TMPMNT}/ostree/deploy/fedora-atomic/deploy/*.0/ <<IEOF
echo -e '[main]\ndns=none' > /etc/NetworkManager/conf.d/dont-touch-resolvconf.conf
IEOF


# umount and tear down loop device
umount $TMPMNT
vgchange -a n atomicos
losetup -d $LOOPDEV
[ ! -z $LOMAJOR ] && rm -f $LOOPDEV #Only remove if we created it

# finally, cp $IMG into /tmp/doimg/ on the host
cp -a $IMG /tmp/doimg/ 

EOF
