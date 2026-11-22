#!/bin/sh
# build.sh: TinyEMU (https://github.com/dearchap/tinyemu at 4a5d5d0, Fabrice Bellard's 2018-09-23 release) to one
# LLVM module, build/linked.ll: the objects of its Makefile's temu with SLIRP and the 128-bit RISC-V CPU, without SDL
# and the network filesystem (they need SDL, libcurl and OpenSSL). riscv_cpu.c is compiled three times, as the
# Makefile does. compat/ supplies the Linux headers macOS lacks; the sources are unchanged.
set -eu
cd "$(dirname "$0")"
R=$(cd ../.. && pwd)
L=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
[ -d src ] || { git clone -q https://github.com/dearchap/tinyemu src && git -C src checkout -q 4a5d5d0747d4d8aa099a91404d360a68d2b9ceff; }
mkdir -p build/ir
cc() { "$L/clang" -O1 -w -include "$R/spec/CQ.h" -Icompat -include sys/select.h -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE \
    -DCONFIG_VERSION='"2018-09-23"' -DCONFIG_SLIRP -Dst_atim=st_atimespec -Dst_mtim=st_mtimespec -Dst_ctim=st_ctimespec -DCONFIG_RISCV_MAX_XLEN=128 -S -emit-llvm "$@"; }
for c in virtio pci fs cutils iomem simplefb json machine temu fs_disk riscv_machine softfp \
         x86_cpu x86_machine ide ps2 vmmouse pckbd vga \
         slirp/bootp slirp/ip_icmp slirp/mbuf slirp/slirp slirp/tcp_output slirp/cksum slirp/ip_input slirp/misc \
         slirp/socket slirp/tcp_subr slirp/udp slirp/if slirp/ip_output slirp/sbuf slirp/tcp_input slirp/tcp_timer; do
    cc "src/$c.c" -o "build/ir/$(echo "$c" | tr / _).ll"
done
for x in 32 64 128; do cc -DMAX_XLEN=$x src/riscv_cpu.c -o build/ir/riscv_cpu$x.ll; done
"$L/llvm-link" -S build/ir/*.ll -o build/linked.ll
echo "functions: $(grep -c '^define ' build/linked.ll)"
