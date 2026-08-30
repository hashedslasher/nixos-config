#set -x

modprobe -r vfio-pci || true

virsh nodedev-reattach pci_0000_03_00_1 || true

echo 0 > /sys/bus/pci/devices/0000:03:00.0/driver/unbind
echo 1 > /sys/bus/pci/devices/0000:03:00.0/remove
echo 1 > /sys/bus/pci/rescan

virsh nodedev-reattach pci_0000_03_00_0 || true

modprobe amdgpu
modprobe snd_hda_intel

if [ -d /sys/bus/platform/drivers/efi-framebuffer ]; then
    echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind || true
fi
if [ -d /sys/bus/platform/drivers/simple-framebuffer ]; then
    echo "simple-framebuffer.0" > /sys/bus/platform/drivers/simple-framebuffer/bind || true
fi


echo 1 > /sys/class/vtconsole/vtcon0/bind || true
echo 1 > /sys/class/vtconsole/vtcon1/bind || true

systemctl start display-manager
