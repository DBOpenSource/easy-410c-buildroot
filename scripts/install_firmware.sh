#!/bin/bash
echo "Installing Firmware"
echo "Current dir: `pwd`"
echo "Rootfs dir:  $1"
echo "Copying Firmware to rootfs..."
cp -ar ../firmware $1/lib/
