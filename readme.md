# vera-toolchain
The repository contains a Docker-based build toolchain for [Vera Plus](getvera.com).
Vera is a product of Vera Control, Ltd. There is no official toolchain available.
The Vera firmware however is based on OpenWrt.
This project attempts to create a toolchain for building applications and libraries that are Vera-compatible.

Note: Modifying the Vera firmware may cause your Vera to no longer work properly. Only make modifications where you know what you are doing. Any change is at your own risk!

# The hardware
Vera is running a MediaTek MT7621A Wi-Fi SoC.
```
# cat /proc/cpuinfo
system type             : MT7621
machine                 : Sercomm G450
processor               : 0
cpu model               : MIPS 1004Kc V2.15
BogoMIPS                : 583.68
wait instruction        : yes
microsecond timers      : yes
tlb_entries             : 32
extra interrupt vector  : yes
hardware watchpoint     : yes, count: 4, address/irw mask: [0x0ffc, 0x0ffc, 0x0ffb, 0x0ffb]
isa                     : mips1 mips2 mips32r1 mips32r2
ASEs implemented        : mips16 dsp mt
shadow register sets    : 1
kscratch registers      : 0
core                    : 0
VPE                     : 0
VCED exceptions         : not available
VCEI exceptions         : not available

processor               : 1
cpu model               : MIPS 1004Kc V2.15
BogoMIPS                : 583.68
wait instruction        : yes
microsecond timers      : yes
tlb_entries             : 32
extra interrupt vector  : yes
hardware watchpoint     : yes, count: 4, address/irw mask: [0x0ffc, 0x0ffc, 0x0ffb, 0x0ffb]
isa                     : mips1 mips2 mips32r1 mips32r2
ASEs implemented        : mips16 dsp mt
shadow register sets    : 1
kscratch registers      : 0
core                    : 0
VPE                     : 1
VCED exceptions         : not available
VCEI exceptions         : not available
```

```
# uname -a
Linux MiOS_50103920 3.10.14 #1 SMP Wed Dec 4 15:29:43 UTC 2019 mips GNU/Linux
```

```
# cat /proc/version
Linux version 3.10.14 (Edward@is-builder-1204-64.dev.mios.com) (gcc version 4.8.3 (OpenWrt/Linaro GCC 4.8-2014.04 unknown) ) #1 SMP Wed Dec 4 15:29:43 UTC 2019
```

```
# cat /etc/banner
  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   F R E E D O M

 ---------------------------------------------------
      BARRIER BREAKER (Bleeding Edge, r39638)
 ---------------------------------------------------
  ***      MiOS LTD. ( www.mios.com )        ***
  ***                                        ***
  ***               WARNING :                ***
  *** Any changes made to the system without ***
  *** guidance from MiOS support will VOID   ***
  *** your future Support requests           ***
 ---------------------------------------------------
```

```
# openssl version
OpenSSL 1.0.2l  25 May 2017
```

# OpenWrt
The vera firmware is based on a very old version of OpenWrt (kernel 3.10.14).
The Dockerfile uses a specific commit [aba884c](https://github.com/openwrt/archive/tree/aba884cec150a9f4d1de6974a96ff90dff900f79) that is chosen as an attempt to be as close to what could be the source of what is used for the Vera firmware, according the banner, which refers to OpenWrt SVN revision 39638.
In addition a specific cherry-pick is done for OpenSSL, to update it to a version similar to what is running on Vera.
There might be other packages that also have different version than available in r39638 of OpenWrt.

# The Toolchain

## Building the toolchain
The toolchain is build using Docker:
```
    git clone https://github.com/vwout/vera-toolchain.git
    cd vera-toolchain
    docker build . -t vera-toolchain
```
Use the resulting image `vera-toolchain:latest` to build your own code.

During the OpenWrt build, many sources will be downloaded from the internet.
To speed up the OpenWrt build, cached packages can be used from the `openwrt/dl` directory.
These sources are not part of this Github repository (because of size). To create you own cache, copy the downloaded files from the first intermediate image from `/home/vera/archive/dl/` into the `openwrt/dl` directory.

## Toolchain Images
The toolchain image is a multi-stage build.
1. The first stage clones OpenWrt and creates the build environment for the OpenWrt toolchain. The build environment is based on Debian Buster, which means a significantly newer gcc compiler is used than the compiler used to build the Vera firmware toolchain, which is running on Ubuntu 12.04. This introduces some complexity, requiring patchwork, since OpenWrt release Barrier Breaker was never intended to be build with a more recent version of gcc.
2. The second stage create a smaller image, Debian Buster based, that only contains the toolchain, needed for cross compilation of tools for Vera.
   - `/toolchain` contains the MIPS toolchain (mipsel_24kec+dsp_gcc-4.6-linaro_uClibc-0.9.33.2)
   - `/target-rootfs` contains a root-fs as generated by OpenWrt. Ideally, this should exactly match the Vera rootfs, but no attempts have been made so far to make it identical
   - `/ramips/packages` contains a series of packages that are build for mips as part of the OpenWrt build; maybe these can be used on Vera


# To Do
This toolchain is experimental, barely verified and probably has many compatibility issies with the actual Vera firmware.

# References
- http://wiki.micasaverde.com/index.php/Source_Code
- https://community.getvera.com/t/where-is-mcvs-openwrt-source/167274
- https://community.getvera.com/t/which-toolchains-gcc-compilers-are-available-for-targeting-the-vera-3-plus/214841
