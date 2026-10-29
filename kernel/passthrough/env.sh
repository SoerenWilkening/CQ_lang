# env.sh: pins and paths of the tier-1 passthrough (cq-w1-kernel-t1). Sourced by the other scripts.
KREL=v6.12                                         # Linux release (torvalds tag)
KCOMMIT=adc218676eef25575469234709c2d87185ca223a   # the commit v6.12 names
KREPO=https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
KCONFIG=x86_64_defconfig
ELFH_SHA=f8f6e7c6dd33d25948786204f91911371b719a5be00505c22ba9191d06102ba7
WT=/Users/sorenwilkening/Desktop/Projects/wt
KSRC=${KSRC:-$WT/kernel-src}
KTREE=$KSRC/mnt/linux
KOUT=$KSRC/mnt/build
HEAVY=$WT/heavy.sh
LLVM_BIN=/usr/local/opt/llvm@19/bin
OPENSSL=/usr/local/opt/openssl@3     # certs/extract-cert (host) links libcrypto
PASSTHROUGH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export PATH=$KSRC/tools/bin:$LLVM_BIN:/usr/bin:/bin:/usr/sbin:/sbin
# Host programs: -I hostinc (glibc/Linux header shims, see setup.sh); -D_UUID_T -D__GETHOSTUUID_H keep
# macOS from declaring uuid_t, which scripts/mod/file2alias.c defines itself.
# make arguments shared by every kbuild invocation. CONFIG_OBJTOOL= on the command line only switches
# off kbuild's objtool steps (they rewrite ELF objects; ours are bitcode, and objtool needs libelf,
# which macOS lacks); autoconf.h, and so every TU, still sees CONFIG_OBJTOOL=y.
KMAKE=(make -C "$KTREE" O="$KOUT" ARCH=x86_64 LLVM=1 CC="$PASSTHROUGH/kcc" HOSTCC=clang
       HOSTCFLAGS="-I$KSRC/hostinc -I$OPENSSL/include -D_UUID_T -D__GETHOSTUUID_H"
       HOSTLDFLAGS="-L$OPENSSL/lib" KCFLAGS=-O1 CONFIG_OBJTOOL=)
# the pass under test: this checkout's build (CMake, as in BRIEF/CLAUDE.md)
PLUGIN=${PLUGIN:-$(cd "$PASSTHROUGH/../.." && pwd)/build/pass/libCQLower.so}
CHK=$KSRC/check                                    # per-TU results of check1.sh
export KSRC KTREE KOUT LLVM_BIN PLUGIN CHK
