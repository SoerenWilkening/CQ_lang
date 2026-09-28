#!/bin/bash
# gen.sh name... : build $P/<name>.s1.ll from src/<name>.c, llvm-linking every
# src/<name>.lib*.c (each compiled as its OWN TU at -O1 — the multi-TU shape is the
# point: a callee in another TU is an unknown external to its caller's -O1). If
# src/<name>.libs names a shared lib set (one basename per line, e.g. `rd`), the
# files src/<that>.lib*.c are linked too.
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
SRC="$(cd "$(dirname "$0")" && pwd)/src"
P="$S/cepm/p"
mkdir -p "$P"
for b in "$@"; do
  b="${b%.c}"
  [ -f "$SRC/$b.c" ] || { echo "NOSRC $b"; continue; }
  libs=()
  for f in "$SRC/$b".lib*.c; do [ -f "$f" ] && libs+=("$f"); done
  if [ -f "$SRC/$b.libs" ]; then
    while read -r set; do
      [ -z "$set" ] && continue
      for f in "$SRC/$set".lib*.c; do [ -f "$f" ] && libs+=("$f"); done
    done < "$SRC/$b.libs"
  fi
  parts=()
  "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$SRC/$b.c" -o "$P/$b.caller.ll" 2>/dev/null || { echo "GENFAIL $b"; continue; }
  parts+=("$P/$b.caller.ll")
  i=0
  for f in "${libs[@]}"; do
    i=$((i+1))
    "$L/clang" -O1 -emit-llvm -S "$f" -o "$P/$b.lib$i.ll" 2>/dev/null || { echo "GENFAIL $b lib $f"; continue 2; }
    parts+=("$P/$b.lib$i.ll")
  done
  if [ "${#parts[@]}" -gt 1 ]; then
    "$L/llvm-link" -S "${parts[@]}" -o "$P/$b.s1.ll" || { echo "GENFAIL $b link"; continue; }
  else
    cp -f "$P/$b.caller.ll" "$P/$b.s1.ll"
  fi
  n=$(wc -c < "$P/$b.s1.ll"); [ "$n" -lt 200 ] && echo "WARN $b s1 tiny ($n bytes)"
done
exit 0
