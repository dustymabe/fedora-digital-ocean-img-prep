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

set -eux 
mkdir -p /tmp/doimg/
cd /tmp/doimg

IMGURL='https://download.fedoraproject.org/pub/fedora/linux/releases/26/CloudImages/x86_64/images/Fedora-Cloud-Base-26-1.5.x86_64.qcow2'
IMGSUM='37a621dda65b04e8b6eee207088ff7697795cb2affdac13ed77166453989557c'
IMG=$(basename $IMGURL) # Just the file name

# Get the xz image, verify, and decompress the contents
curl -L -O $IMGURL
imgsum=$(sha256sum $IMG | cut -d " " -f 1)
if [ "$imgsum" != "$IMGSUM" ]; then
    echo "Checksum doesn't match: $imgsum"
    exit 1
fi

echo "File is at: $(readlink -f $IMG)"
