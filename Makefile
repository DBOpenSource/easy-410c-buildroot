#
# Build and run an AArch64 buildroot created rootfs on DB410C
#
# root password is root
#

TOPDIR:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
GCCVER:=gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux
GCCDIR:=$(TOPDIR)$(GCCVER)
GCCBINDIR:=$(GCCDIR)/bin
COMMIT=15a53b93a034af78c1a3d62510a2abe5a91e4f8f
#COMMIT = "master"
IMG_DIR=$(TOPDIR)db410c-linux/arch/arm64/boot
BOOT_IMG:=$(TOPDIR)boot-db410c.img

all: db410c

# Variables required for db410c.mk

DOWNLOAD_DIR:=$(TOPDIR)downloads
TMP_DIR:=$(TOPDIR)tmp
FIRMWARE_DEST_DIR:=$(DOWNLOAD_DIR)
ROOTFS_IMG:=$(TOPDIR)buildroot.git/output/images/rootfs.ext4
IMAGE:=$(IMG_DIR)/Image
DTB:=$(IMG_DIR)/dts/qcom/apq8016-sbc.dtb

# Use the rules in db410c.mk to build the kernel
BUILD_DEFAULT_KERNEL=1
DB410C_KERNEL:=$(TOPDIR)/db410c-linux
KERNEL_CONFIG:=$(TOPDIR)/db410c_config

db410c_makefiles/db410c.mk:
	git clone git@github.com:DBOpenSource/db410c_makefiles.git

# Use the rules to build $(ROOTFS_IMG) $(BOOT_IMG)
-include db410c_makefiles/db410c.mk

# Get buildroot
buildroot.git:
	git clone git://git.buildroot.net/buildroot $@

# Get Linaro AArch64 cross compiler
$(GCCDIR)/.exists: $(DOWNLOAD_DIR)/.exists
	@(cd $(DOWNLOAD_DIR) && wget http://releases.linaro.org/14.09/components/toolchain/binaries/$(GCCVER).tar.xz)
	tar xJf $(DOWNLOAD_DIR)/$(GCCVER).tar.xz
	touch $@

# Make the rootfs
$(ROOTFS_IMG): buildroot.git $(GCCDIR)/.complete buildroot_config
	cp buildroot_config buildroot.git/.config
	sed -i "s#BR2_TOOLCHAIN_EXTERNAL_PATH=.*#BR2_TOOLCHAIN_EXTERNAL_PATH=\"$(GCCDIR)\"#" buildroot.git/.config
	(cd buildroot.git && git checkout $(COMMIT))
	(cd buildroot.git && patch -p1 < ../buildroot.patch)
	(cd buildroot.git && make oldconfig && make)

# Make the DB410c kernel and rootfs
db410c: $(ROOTFS_IMG) $(BOOT_IMG) 
	@echo ROOTFS_IMG = $(ROOTFS_IMG)
	@echo BOOT_IMG = $(BOOT_IMG)

clean-rootfs:
	[ -d buildroot.git ] && (cd buildroot.git && make clean && git checkout .)

clean-kernel:
	[ -d $(DB410C_KERNEL) ] && (cd $(DB410C_KERNEL) && ARCH=arm64 make clean)

