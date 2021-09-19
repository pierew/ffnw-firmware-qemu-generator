#!/bin/bash

function GET_ORIG_FILE_DATE() {
    echo $(echo $1 | cut -d"/" -f7 | cut -d"-" -f3)
}

function GET_FILE_NAME() {
    echo $(echo $1 | cut -d"/" -f7)
}

PATH_DUMP="/var/lib/vz/dump"
PATH_QEMU_IMG="/var/lib/vz/images"
PATH_CDN_STABLE="/var/www/localhost/htdocs/files/ffnw/firmware/l2tp/stable"
PATH_CDN_TESTING="/var/www/localhost/htdocs/files/ffnw/firmware/l2tp/testing"
PATH_CDN_EXPERIMENTAL="/var/www/localhost/htdocs/files/ffnw/firmware/l2tp/experimental"
CDN_SERVER="192.168.66.203"

#IMG_X86_STABLE="https://firmware.ffnw.de/l2tp/stable/factory/gluon-ffnw-20210427-x86-generic.img.gz"
VMID_X86_STABLE=130

#IMG_X86_X64_STABLE="https://firmware.ffnw.de/l2tp/stable/factory/gluon-ffnw-20210427-x86-64.img.gz"
VMID_X86_X64_STABLE=127

#IMG_X86_TESTING="https://firmware.ffnw.de/l2tp/testing/factory/gluon-ffnw-20180709_testing-x86-generic.img.gz"
VMID_X86_TESTING=129

#IMG_X86_X64_TESTING="https://firmware.ffnw.de/l2tp/testing/factory/gluon-ffnw-20180709_testing-x86-64.img.gz"
VMID_X86_X64_TESTING=128

#IMG_X86_EXPERIMENTAL="https://firmware.ffnw.de/l2tp/nightly/master/gluon-ffnw-20210813-x86-generic.img.gz"
VMID_X86_EXPERIMENTAL=132

#IMG_X86_X64_EXPERIMENTAL="https://firmware.ffnw.de/l2tp/nightly/master/gluon-ffnw-20210813-x86-64.img.gz"
VMID_X86_X64_EXPERIMENTAL=131

PROXMOX_VMID_START=127
PROXMOX_VMID_STOP=132
PROXMOX_NODE="proxmox01"

echo "Enter X86 Stable URL: "
read IMG_X86_STABLE

echo "Enter X86_X64 Stable URL: "
read IMG_X86_X64_STABLE

echo "Enter X86 Testing URL: "
read IMG_X86_TESTING

echo "Enter X86_X64 Testing URL: "
read IMG_X86_X64_TESTING

echo "Enter X86 Experimental URL: "
read IMG_X86_EXPERIMENTAL

echo "Enter X86_X64 Experimental URL: "
read IMG_X86_X64_EXPERIMENTAL

echo "CONVERT QCOW2 TO RAW"
for VMID in $(seq $PROXMOX_VMID_START $PROXMOX_VMID_STOP)
do
    qm move_disk $VMID virtio0 local --delete 1 --format raw
    qm 
done

echo "DOWNLOAD IMAGES"

wget $IMG_X86_STABLE -O /tmp
wget $IMG_X86_X64_STABLE -O /tmp

wget $IMG_X86_TESTING -O /tmp
wget $IMG_X86_X64_TESTING -O /tmp

wget $IMG_X86_EXPERIMENTAL -O /tmp
wget $IMG_X86_X64_EXPERIMENTAL -O /tmp

echo "EXTRACT IMAGES"

gzip -c /tmp/$(GET_FILE_NAME $IMG_X86_STABLE) > $PATH_QEMU_IMG/$VMID_X86_STABLE/vm-$VMID_X86_STABLE-disk-0.raw
gzip -c /tmp/$(GET_FILE_NAME $IMG_X86_X64_STABLE) > $PATH_QEMU_IMG/$VMID_X86_X64_STABLE/vm-$VMID_X86_X64_STABLE-disk-0.raw
gzip -c /tmp/$(GET_FILE_NAME $IMG_X86_TESTING) > $PATH_QEMU_IMG/$VMID_X86_ESTING/vm-$VMID_X86_ESTING-disk-0.raw
gzip -c /tmp/$(GET_FILE_NAME $IMG_X86_X64_TESTING) > $PATH_QEMU_IMG/$VMID_X86_X64_SESTING/vm-$VMID_X86_X64_ESTING-disk-0.raw
gzip -c /tmp/$(GET_FILE_NAME $IMG_X86_EXPERIMENTAL) > $PATH_QEMU_IMG/$VMID_X86_EXPERIMENTAL/vm-$VMID_X86_EXPERIMENTAL-disk-0.raw
gzip -c /tmp/$(GET_FILE_NAME $IMG_X86_X64_EXPERIMENTAL) > $PATH_QEMU_IMG/$VMID_X86_X64_EXPERIMENTAL/vm-$VMID_X86_X64_EXPERIMENTAL-disk-0.raw

echo "CONVERT RAW TO QCOW2"

for VMID in $(seq $PROXMOX_VMID_START $PROXMOX_VMID_STOP)
do
    qm move_disk $VMID virtio0 local --delete 1 --format qcow2
done

pvesh set /nodes/$PROXMOX_NODE/qemu/$VMID_X86_STABLE/config -name "gluon-ffnw-$(GET_ORIG_FILE_DATE $IMG_X86_STABLE)-stable-x86-qemu"
pvesh set /nodes/$PROXMOX_NODE/qemu/$VMID_X86_X64_STABLE/config -name "gluon-ffnw-$(GET_ORIG_FILE_DATE $IMG_X86_X64_STABLE)-stable-x86-x64-qemu"

pvesh set /nodes/$PROXMOX_NODE/qemu/$VMID_X86_TESTING/config -name "gluon-ffnw-$(GET_ORIG_FILE_DATE $IMG_X86_TESTING)-testing-x86-qemu"
pvesh set /nodes/$PROXMOX_NODE/qemu/$VMID_X86_X64_TESTING/config -name "gluon-ffnw-$(GET_ORIG_FILE_DATE $IMG_X86_X64_TESTING)-testing-x86-x64-qemu"

pvesh set /nodes/$PROXMOX_NODE/qemu/$VMID_X86_EXPERIMENTAL/config -name "gluon-ffnw-$(GET_ORIG_FILE_DATE $IMG_X86_EXPERIMENTAL)-experimental-x86-qemu"
pvesh set /nodes/$PROXMOX_NODE/qemu/$VMID_X86_X64_EXPERIMENTAL/config -name "gluon-ffnw-$(GET_ORIG_FILE_DATE $IMG_X86_X64_EXPERIMENTAL)-experimental-x86-x64-qemu"

echo "EXPORT VMS"

for VMID in $(seq $PROXMOX_VMID_START $PROXMOX_VMID_STOP)
do
    vzdump $VMID --stop --compress zstd --dumpdir $PATH_DUMP
done

echo "UPLOAD TO CDN"

scp $PATH_DUMP/vzdump-qemu-$VMID_X86_STABLE-*.zst $CDN_SERVER:$PATH_CDN_STABLE/gluon-ffnw-$(GET_ORIG_FILE_DATE $IMG_X86_STABLE)-stable-x86-qemu.vma.zst
scp $PATH_DUMP/vzdump-qemu-$VMID_X86_X64_STABLE-*.zst $CDN_SERVER:$PATH_CDN_STABLE/gluon-ffnw-$(GET_ORIG_FILE_DATE $IMG_X86_X64_STABLE)-stable-x86_x64-qemu.vma.zst

scp $PATH_DUMP/vzdump-qemu-$VMID_X86_TESTING-*.zst $CDN_SERVER:$PATH_CDN_TESTING/gluon-ffnw-$(GET_ORIG_FILE_DATE $IMG_X86_TESTING)-testing-x86-qemu.vma.zst
scp $PATH_DUMP/vzdump-qemu-$VMID_X86_X64_TESTING-*.zst $CDN_SERVER:$PATH_CDN_TESTING/gluon-ffnw-$(GET_ORIG_FILE_DATE $IMG_X86_X64_TESTING)-testing-x86_x64-qemu.vma.zst

scp $PATH_DUMP/vzdump-qemu-$VMID_X86_EXPERIMENTAL-*.zst $CDN_SERVER:$PATH_CDN_EXPERIMENTAL/gluon-ffnw-$(GET_ORIG_FILE_DATE $IMG_X86_EXPERIMENTAL)-experimental-x86_x64-qemu.vma.zst
scp $PATH_DUMP/vzdump-qemu-$VMID_X86_X64_EXPERIMENTAL-*.zst $CDN_SERVER:$PATH_CDN_EXPERIMENTAL/gluon-ffnw-$(GET_ORIG_FILE_DATE $IMG_X86_X64_EXPERIMENTAL)-experimental-x86_x64-qemu.vma.zst


