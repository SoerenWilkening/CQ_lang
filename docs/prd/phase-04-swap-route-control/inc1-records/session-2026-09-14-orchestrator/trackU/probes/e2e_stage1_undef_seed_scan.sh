#!/bin/bash
LLVM=/usr/local/opt/llvm@19/bin
cd /Users/sorenwilkening/Desktop/CQ_undef
: > /tmp/e2e_undef_scan2.txt
one(){
  f="$1"; b=$(basename "$f")
  case "$b" in *_lib.c) return;; esac
  t=$(mktemp -d)
  if "$LLVM/clang" -Iinclude -include CQ.h -O1 -emit-llvm -S "$f" -o "$t/s1.ll" 2>/dev/null; then
    python3 - "$t/s1.ll" "$b" <<'PY' >> /tmp/e2e_undef_scan2.txt
import re,sys
ir=open(sys.argv[1]).read(); b=sys.argv[2]
for m in re.finditer(r'@cq_theta_[a-z0-9]+\(([^)]*)\)', ir):
    args=[a.strip() for a in m.group(1).split(',')]
    if args and args[0].split()[-1] in ('undef','poison'): print('SEED-UNDEF', b, m.group(0)[:70])
    if len(args)>1 and args[1].split()[-1] in ('undef','poison'): print('ANGLE-UNDEF', b, m.group(0)[:70])
PY
  else echo "CLANGERR $b" >> /tmp/e2e_undef_scan2.txt; fi
  rm -rf "$t"
}
export -f one; export LLVM
ls tests/e2e/*.c | xargs -P 2 -I{} bash -c 'one "$@"' _ {}
echo "DONE" >> /tmp/e2e_undef_scan2.txt
