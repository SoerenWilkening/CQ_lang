#!/bin/sh
# Which fixtures still DECLINE at `declineDephasingUnmarkedLoopRails`?
# The cheap way to re-home the bd `bbu0` DEFER instrument pin when its L8
# retirement trigger fires again. Run from a repo root; $1 = build dir.
set -eu
BD="${1:-build}"
test -x "$BD/ir-pass/cq-opt" || { echo "no cq-opt at $BD/ir-pass/cq-opt" >&2; exit 2; }
for f in ir-pass/test/loop_leak_dephase_*.ll ir-pass/test/loop_pairing_*.ll; do
  out=$("$BD/ir-pass/cq-opt" -passes=cq-lowering -S "$f" -o /dev/null 2>&1) || true
  case "$out" in
    *"rolled body leaks a rail entangled with a rotated register"*)
      echo "FENCE-HOST  $f" ;;
  esac
done
