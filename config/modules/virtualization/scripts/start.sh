#!/run/current-system/sw/bin/bash
#set -x

systemctl stop display-manager

sleep 2

echo 3 > /sys/bus/pci/devices/0000:03:00.0/resource2_resize

echo 0 > /sys/class/vtconsole/vtcon0/bind || true
echo 0 > /sys/class/vtconsole/vtcon1/bind || true

if [ -d /sys/bus/platform/drivers/efi-framebuffer ]; then
    echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/unbind || true
fi
if [ -d /sys/bus/platform/drivers/simple-framebuffer ]; then
    echo "simple-framebuffer.0" > /sys/bus/platform/drivers/simple-framebuffer/unbind || true
fi

modprobe -r snd_hda_intel || true
modprobe -r amdgpu

virsh nodedev-detach pci_0000_03_00_1 || true
virsh nodedev-detach pci_0000_03_00_0 || true

modprobe vfio-pci
