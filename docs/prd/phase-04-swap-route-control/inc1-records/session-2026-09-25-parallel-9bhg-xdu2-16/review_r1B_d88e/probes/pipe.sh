#!/bin/bash
# pipe.sh TAG "args" name... : run cq-opt.TAG on p/<name>.s1.ll, 2b strict, link, run with args.
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-acf961e52a2f9e440
R=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/rB_d88e
cd "$R/p" || exit 1
TAG="$1"; shift; ARGS="$1"; shift
for b in "$@"; do
  b="${b%.c}"; f="$b.s1.ll"
  [ -s "$f" ] || { echo "$b MISSING"; continue; }
  "$R/bin/cq-opt.$TAG" -passes=cq-lowering -S "$f" -o "$b.$TAG.s2.ll" 2> "$b.$TAG.err"
  rc=$?
  echo "=== $b [$TAG] opt rc=$rc stderr_bytes=$(wc -c < "$b.$TAG.err")"
  sed 's/^/  ERR: /' "$b.$TAG.err" | head -6
  if [ "$rc" = 0 ]; then
    python3 "$W/tools/free_pairing_check.py" "$b.$TAG.s2.ll" > "$b.$TAG.2b" 2>&1; rc2=$?
    echo "  2b rc=$rc2: $(tr '\n' ' ' < "$b.$TAG.2b" | cut -c1-400)"
    echo "  measures=$(grep -c 'call .*@cqrt_measure' "$b.$TAG.s2.ll")"
    "$L/clang" "$b.$TAG.s2.ll" "$R/rt/libcq_templates.a" "$R/rt/libcq_runtime.a" -o "$b.$TAG.exe" 2>/dev/null || { echo "  LINKFAIL"; continue; }
    # shellcheck disable=SC2086
    "./$b.$TAG.exe" $ARGS > "$b.$TAG.trace" 2>&1; e=$?
    echo "  run($ARGS) exit=$e lines=$(wc -l < "$b.$TAG.trace")"
    sed 's/^/    /' "$b.$TAG.trace"
  fi
done
exit 0
