#!/bin/bash
# run_mut.sh NAME... : for each mutant, splice source, build cq-opt+debugalloc, run full lit, restore.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
W=$S/r2B9/asan_wt; M=$S/r2B9/mut
cd $W
for n in "$@"; do
  f=$(head -1 $M/$n.patchsrc)
  cp -f $M/$n.cpp $W/$f
  if ! cmake --build build_mut --target cq-opt cq-opt-debugalloc -j6 > $M/$n.build.log 2>&1; then
    echo "$n BUILD FAILED"; git checkout -- $f; continue
  fi
  mkdir -p $M/$n.bin; cp -f build_mut/ir-pass/cq-opt build_mut/ir-pass/cq-opt-debugalloc $M/$n.bin/
  h=$(shasum -a 256 build_mut/ir-pass/cq-opt | cut -c1-16)
  lit -s -j6 build_mut/ir-pass/test > $M/$n.lit.txt 2>&1
  fails=$(grep -c '^FAIL: \|^  CQ-IRPass :: ' $M/$n.lit.txt)
  echo "$n cq-opt=$h $(grep -E 'Passed|Failed' $M/$n.lit.txt | tr -s ' ' | tr '\n' ' ')"
  git checkout -- $f
done
cmake --build build_mut --target cq-opt cq-opt-debugalloc -j6 > $M/restore.build.log 2>&1
echo "restored cq-opt=$(shasum -a 256 build_mut/ir-pass/cq-opt | cut -c1-16) dbg=$(shasum -a 256 build_mut/ir-pass/cq-opt-debugalloc | cut -c1-16)"
