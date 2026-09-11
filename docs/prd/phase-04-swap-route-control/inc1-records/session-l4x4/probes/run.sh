#!/bin/zsh
# l4x4 probe runner. Read-only against the repo; writes only here.
REPO=/Users/sorenwilkening/Desktop/CQ_lang
LLVM=/usr/local/opt/llvm@19/bin
P=$1
"$LLVM/clang" -I$REPO/include -include CQ.h -O1 -emit-llvm -S $P.c -o $P.s1.ll 2> $P.cc.err || { echo "$P CLANG-FAIL"; cat $P.cc.err; exit 1; }
BRS=$(grep -c 'br i1' $P.s1.ll)
SEL=$(grep -c ' = select ' $P.s1.ll)
"$REPO/build/ir-pass/cq-opt" -load-pass-plugin "$REPO/build/ir-pass/libCQPass.so" -passes=cq-lowering -S $P.s1.ll -o $P.s2.ll > $P.out 2> $P.err
RC=$?
MSG=$(grep -o "cq [a-z0-9 -]*: [^;]*" $P.err | head -1)
printf '%-28s rc=%d brs=%s sel=%s  %s\n' "$P" "$RC" "$BRS" "$SEL" "${MSG:-<accept>}"
