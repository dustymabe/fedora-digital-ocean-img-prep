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

IMGURL='https://kojipkgs.fedoraproject.org/compose/twoweek/Fedora-Atomic-26-20170707.1/compose/CloudImages/x86_64/images/Fedora-Atomic-26-20170707.1.x86_64.qcow2'
IMGSUM='d342c0923b57090c60f2df26bb7a0531924ee00b66f2d05ddf32e0741ad032bb'

# Get the xz image, verify, and decompress the contents
curl -O $IMGURL
imgsum=$(sha256sum $IMG | cut -d " " -f 1)
if [ "$imgsum" != "$IMGSUM" ]; then
    echo "Checksum doesn't match: $imgsum"
    exit 1
fi
