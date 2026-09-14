#!/bin/bash
# One corpus row: ORACLE vs SUBJECT on the SAME stage-1 module.
# Emits: <kind> <path> <o_exit> <o_errsha> <o_md5> <s_exit> <s_errsha> <s_md5> <o_dbg> <s_dbg>
# o_dbg/s_dbg: 1 if the diagnostic carries a real source location, 0 if <unknown>:0:0, - if accept.
set -u
L=/usr/local/opt/llvm@19/bin
ORB=/Users/sorenwilkening/Desktop/CQ_lang/build
SUB=/Users/sorenwilkening/Desktop/CQ_merge/build
f="$1"
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
case "$f" in
  *.c)
    if ! "$L/clang" -I/Users/sorenwilkening/Desktop/CQ_merge/include -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$t/s1.ll" 2>/dev/null; then
      echo "CLANGERR $f"; exit 0; fi
    m="$t/s1.ll" ;;
  *) m="$f" ;;
esac
if [ ! -s "$m" ]; then echo "EMPTY $f"; exit 0; fi
"$ORB/ir-pass/cq-opt" -load-pass-plugin "$ORB/ir-pass/libCQPass.so" -passes=cq-lowering -S "$m" -o "$t/o.ll" 2>"$t/o.err"; oe=$?
"$SUB/ir-pass/cq-opt" -load-pass-plugin "$SUB/ir-pass/libCQPass.so" -passes=cq-lowering -S "$m" -o "$t/s.ll" 2>"$t/s.err"; se=$?
oes=$(shasum -a 256 "$t/o.err" | cut -c1-16)
ses=$(shasum -a 256 "$t/s.err" | cut -c1-16)
om="-"; sm="-"
[ $oe -eq 0 ] && [ -s "$t/o.ll" ] && om=$(md5 -q "$t/o.ll")
[ $se -eq 0 ] && [ -s "$t/s.ll" ] && sm=$(md5 -q "$t/s.ll")
od="-"; sd="-"
if [ $oe -ne 0 ]; then if grep -q '<unknown>:0:0' "$t/o.err"; then od=0; else od=1; fi; fi
if [ $se -ne 0 ]; then if grep -q '<unknown>:0:0' "$t/s.err"; then sd=0; else sd=1; fi; fi
if [ "$oe" != "$se" ]; then k=VERDICTMOVE
elif [ "$oes" != "$ses" ]; then k=STRMOVE
elif [ "$om" != "$sm" ]; then k=IRDIFF
else k=SAME; fi
echo "$k $f $oe $oes $om $se $ses $sm $od $sd"
