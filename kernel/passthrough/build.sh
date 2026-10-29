#!/bin/bash
# build.sh: rebuild the pinned kernel's TUs as -O1 bitcode (cq-w1-kernel-t1), in resumable batches.
#   build.sh config     x86_64_defconfig into $KOUT
#   build.sh prepare    kbuild's prepare (generated headers, host programs)
#   build.sh dir D      one batch: `make -k -j8 D/`
#   build.sh list       the batch directories
#   build.sh dirs       one `make -k -j8 <dir>/` per batch directory (see BATCHES), each under heavy.sh
#   build.sh rest       a final `make -k -j8 vmlinux modules` for anything the batches left
#   build.sh all        all of the above, in order
# Every make runs under heavy.sh at -j8 (600 s cap). A killed batch is rerun as is: make resumes where
# it stopped. Logs go to $KSRC/logs. Link steps fail by construction (the objects are bitcode, and
# objtool/modpost need ELF): -k keeps every compile going, the failures are listed by report.py.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/env.sh"
mkdir -p "$KSRC/logs"
J=8
# batch directories: the top-level vmlinux/module directories of x86_64, the big ones split one level
BATCHES=(init usr arch/x86 kernel certs mm ipc security crypto block io_uring virt lib sound
         fs/ext4 fs/nfs fs/xfs fs net/ipv4 net/ipv6 net/netfilter net
         drivers/gpu drivers/net drivers/usb drivers/scsi drivers/ata drivers/acpi drivers/tty
         drivers/input drivers/hid drivers/pci drivers/md drivers/char drivers/base drivers)

run() {  # run <log> <make target...>: rerun after a heavy.sh kill (exit 124), at most 6 times
  local log=$1; shift; local n=0 st
  while :; do
    n=$((n+1))
    "$HEAVY" -t 600 "${KMAKE[@]}" -k -j$J "$@" >>"$log" 2>&1; st=$?
    [ $st -ne 124 ] && break
    [ $n -ge 6 ] && { echo "build: $* still killed after $n runs" >&2; return 124; }
    echo "build: $* killed at the cap, resuming ($n)" >&2
  done
  echo "build: $* exit $st (log $log)"
}
step() {
  case $1 in
    config) [ -f "$KOUT/.config" ] || run "$KSRC/logs/config.log" "$KCONFIG" ;;
    prepare) run "$KSRC/logs/prepare.log" prepare ;;
    dir) run "$KSRC/logs/dir-${2//\//_}.log" "$2/" ;;
    dirs) for d in "${BATCHES[@]}"; do step dir "$d"; done ;;
    list) echo "${BATCHES[@]}" ;;
    rest) run "$KSRC/logs/rest.log" vmlinux modules ;;
    all) step config; step prepare; step dirs; step rest ;;
    *) echo "usage: build.sh config|prepare|dir D|list|dirs|rest|all" >&2; exit 2 ;;
  esac
}
step "${1:-all}" "${2:-}"
