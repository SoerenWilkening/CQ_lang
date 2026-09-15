#!/bin/zsh
# rv.sh <module.ll> [more.ll ...]  — run every binary on each module, print verdicts
LLVM=/usr/local/opt/llvm@19/bin
SCR=$SCRATCH
typeset -A B
B[ORACLE]=/Users/sorenwilkening/Desktop/CQ_lang/build
B[BASE_F]=/Users/sorenwilkening/Desktop/CQ_F/build
B[SUBJ_P]=/Users/sorenwilkening/Desktop/CQ_P/build
B[P_ALONE]=$SCR/R4/build
for f in "$@"; do
  sz=$(wc -c < "$f" | tr -d ' ')
  echo "=== $f  (${sz} bytes)"
  if [ "$sz" -lt 20 ]; then echo "  !! EMPTY/TINY MODULE — vacuity trap"; continue; fi
  for k in ORACLE BASE_F SUBJ_P P_ALONE; do
    d=${B[$k]}
    [ -x "$d/ir-pass/cq-opt" ] || { printf "  %-8s (binary absent)\n" "$k"; continue; }
    out=$("$d/ir-pass/cq-opt" -load-pass-plugin "$d/ir-pass/libCQPass.so" -passes=cq-lowering -S "$f" -o "${f%.ll}.$k.s2.ll" 2>&1); rc=$?
    if [ $rc -eq 0 ]; then
      md5=$(grep -v '^; ModuleID\|^source_filename' "${f%.ll}.$k.s2.ll" | md5 -q)
      printf "  %-8s ACCEPT   md5=%s\n" "$k" "${md5:0:12}"
    else
      msg=$(echo "$out" | grep -o 'cq [a-z ]*lowering: [^\n]*' | head -1)
      [ -z "$msg" ] && msg=$(echo "$out" | head -2 | tr '\n' ' ')
      printf "  %-8s exit=%s  %s\n" "$k" "$rc" "$msg"
    fi
  done
done
