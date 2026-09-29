#!/bin/bash
# ctest_affected.sh OUTFILE : reconfigure (picks up new e2e registrations; never
# rebuilds cq-opt) and run the ctest entries this bead can witness.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
cd "$W" || exit 1
cmake -S . -B build > /dev/null 2>&1 || { echo "cmake failed"; exit 1; }
shasum -a 256 build/ir-pass/cq-opt | cut -c1-24
ctest --test-dir build -j4 --output-on-failure \
  -R 'e2e-slice-spec|e2e-spec-|libm-real-atan2l|libm-real-coshl|trace-twin-equiv|e2e-census-slice-sync|e2e-keepset-vendor-check|e2e-free-pairing-selftest' \
  > "$1" 2>&1
tail -6 "$1"
