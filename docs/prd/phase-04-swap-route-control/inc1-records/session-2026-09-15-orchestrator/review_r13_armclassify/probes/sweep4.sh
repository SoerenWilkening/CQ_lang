#!/bin/zsh
# sweep4.sh <file.ll> -> one row: relpath|ORACLE|BASE_F|P_ALONE|SUBJ_P
f="$1"
SCR=$SCRATCH
t=$(mktemp -d)
row="$f"
for d in /Users/sorenwilkening/Desktop/CQ_lang/build /Users/sorenwilkening/Desktop/CQ_F/build /Users/sorenwilkening/Desktop/CQ_P/build $SCR/R4/build; do
  err="$t/e"; out="$t/o.ll"
  "$d/ir-pass/cq-opt" -load-pass-plugin "$d/ir-pass/libCQPass.so" -passes=cq-lowering -S "$f" -o "$out" 2>"$err"; rc=$?
  if [ $rc -eq 0 ]; then
    if [ ! -s "$f" ]; then cell="EMPTY"; else cell="A:$(grep -v '^; ModuleID\|^source_filename' "$out" | md5 -q)"; fi
  else
    # full stderr, argv/stack-dump normalised away (PROTOCOL S3 + Track P's correction)
    cell="D$rc:$(grep -v 'Stack dump\|Program arguments\|^ *#[0-9]\|PLEASE submit\|^0x\|^[0-9]\+\.' "$err" | md5 -q)"
  fi
  row="$row|$cell"
done
rm -rf "$t"
echo "$row"
