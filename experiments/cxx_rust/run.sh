#!/bin/zsh
# run.sh <dir: cxx | rust> [files...]: every program through its front end, the pass and the C-oracle check (entry f).
# EXC=1: C++ with exceptions on (default -fno-exceptions, so throwing programs are skipped by the compiler, not us).
# Prints one line per program: frontend / pass / check stage reached and the first error line.
H=${0:A:h}; R=${CQ_ROOT:-${H:h:h}}; L=/usr/local/opt/llvm@19/bin
D=$1; shift; O=${OUT:-$H/out/$D${EXC:+-exc}}; mkdir -p $O
export CQ_BUILD_DIR=${CQ_BUILD_DIR:-$R/build}
TL() { perl -e 'alarm shift; exec @ARGV' "$@"; }
[ $# -gt 0 ] || set -- $H/$D/*.(cpp|rs)(N)
for s in "$@"; do
  b=${s:t:r}; ll=$O/$b.ll
  if [ $D = cxx ]; then
    $L/clang++ -std=c++20 -O1 ${=CXXFLAGS:-} $([ -n "$EXC" ] || echo -fno-exceptions) -I$H -S -emit-llvm $s -o $ll > $O/$b.err 2>&1
  else
    $H/rust.sh $s $ll > $O/$b.err 2>&1
  fi || { echo "$b FRONTEND $(grep -m1 error $O/$b.err)"; continue; }
  TL 300 $R/driver/cqcc -S $ll -cq-k-default=${K:-8} --cq-check --cq-entry f --cq-samples ${N:-40} -o $O/$b.lowered.ll > $O/$b.log 2>&1
  r=$?
  if [ $r = 0 ]; then echo "$b PASS"
  elif [ $r = 142 ]; then echo "$b TIMEOUT"
  else echo "$b rc=$r $([ -f $O/$b.lowered.ll ] && echo checked || echo pass-failed) | $(grep -vE '^\s*$|Stack dump|PLEASE' $O/$b.log | grep -m1 -iE 'cq:|error|assert|fail|differ|unimpl' | cut -c1-230)"; fi
done
