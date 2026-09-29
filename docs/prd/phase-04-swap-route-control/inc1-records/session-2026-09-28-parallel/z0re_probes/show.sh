#!/bin/bash
# print every function body (minus dbg intrinsics / blank lines) of each .ll given
for f in "$@"; do
  echo "=== $f"
  awk "/^define/{p=1} p{print} /^}/{p=0}" < "$f" | grep -v -e 'llvm.dbg' -e '^$'
done
