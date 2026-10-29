#!/bin/bash
# setup.sh: one-time host preparation for the tier-1 passthrough build (cq-w1-kernel-t1).
# Everything lives outside the repository under $KSRC (default ../wt/kernel-src); nothing is committed.
#   - a case-sensitive APFS sparse image mounted at $KSRC/mnt (the kernel tree has names that differ
#     only in case, e.g. net/netfilter/xt_TCPMSS.c and xt_tcpmss.c)
#   - a shallow clone of the pinned release into $KSRC/mnt/linux
#   - GNU make 4.4.1 and GNU sed 4.9 built into $KSRC/tools (macOS ships make 3.81 and BSD sed)
#   - $KSRC/hostinc for the host programs (modpost, relocs, sorttable, mdp): glibc 2.40's elf.h and
#     the shims in hostinc/ here (byteswap.h, endian.h, asm/{types,posix_types,bitsperlong,byteorder}.h;
#     the asm ones include the tree's uapi asm-generic headers by a path relative to $KSRC/hostinc)
#   - $KSRC/tools/bin: the LLVM=1 tool names, linked to brew llvm@19 and lld@19 (19.1.7; lld@19 is
#     keg-only: `brew install lld@19`)
# Network and compile steps are light; the two tool builds go through heavy.sh.
set -euo pipefail
[ -x /usr/local/opt/lld@19/bin/ld.lld ] || { echo "setup: brew install lld@19 first" >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)
. "$here/env.sh"
mkdir -p "$KSRC" "$KSRC/dl" "$KSRC/hostinc" "$KSRC/tools/bin" "$KSRC/mnt"
[ -f "$KSRC/cqlinux.sparseimage" ] || hdiutil create -size 30g -type SPARSE -fs "Case-sensitive APFS" \
  -volname cqlinux "$KSRC/cqlinux.sparseimage"
mount | grep -q " $KSRC/mnt " || hdiutil attach -nobrowse -mountpoint "$KSRC/mnt" "$KSRC/cqlinux.sparseimage"
if [ ! -d "$KTREE/.git" ]; then
  git clone --depth 1 --branch "$KREL" --single-branch "$KREPO" "$KTREE"
fi
[ "$(git -C "$KTREE" rev-parse HEAD)" = "$KCOMMIT" ] || { echo "setup: $KTREE is not $KREL ($KCOMMIT)" >&2; exit 1; }
cd "$KSRC/dl"
fetch() { [ -f "$2" ] || curl -sSLo "$2" "$1"; echo "$3  $2" | shasum -a 256 -c - >/dev/null || { echo "setup: bad sha256 for $2" >&2; exit 1; }; }
fetch https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz make-4.4.1.tar.gz dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3
fetch https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz sed-4.9.tar.xz 6e226b732e1cd739464ad6862bd1a1aba42d7982922da7a53519631d24975181
fetch 'https://sourceware.org/git/?p=glibc.git;a=blob_plain;f=elf/elf.h;hb=refs/tags/glibc-2.40' elf.h "$ELFH_SHA"
cp elf.h "$KSRC/hostinc/elf.h"
cp -R "$here/hostinc/." "$KSRC/hostinc/"
if [ ! -x "$KSRC/tools/bin/make" ]; then
  tar xzf make-4.4.1.tar.gz && tar xJf sed-4.9.tar.xz
  "$HEAVY" -t 400 sh -c "cd make-4.4.1 && ./configure --prefix=$KSRC/tools --disable-nls >/dev/null && make -j4 >/dev/null && make install >/dev/null && cd ../sed-4.9 && ./configure --prefix=$KSRC/tools --disable-nls --program-prefix=g >/dev/null && make -j4 >/dev/null && make install >/dev/null"
fi
cd "$KSRC/tools/bin"
for t in clang clang-19 llvm-ar llvm-nm llvm-objcopy llvm-objdump llvm-readelf llvm-strip; do ln -sf "$LLVM_BIN/$t" .; done
ln -sf /usr/local/opt/lld@19/bin/ld.lld .
ln -sf gsed sed
echo "setup: ok ($KREL $KCOMMIT)"
