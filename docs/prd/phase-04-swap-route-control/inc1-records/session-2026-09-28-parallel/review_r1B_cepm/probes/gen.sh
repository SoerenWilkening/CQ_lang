#!/bin/bash
# gen.sh SRCDIR name... : like the implementer's gen.sh but writes into $S/r1B_cepm/p
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
SRC="$1"; shift
P="$S/r1B_cepm/p"
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
done
