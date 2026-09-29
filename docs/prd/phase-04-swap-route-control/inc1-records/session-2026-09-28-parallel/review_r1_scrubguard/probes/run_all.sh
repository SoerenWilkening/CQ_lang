#!/bin/sh
# Review r1 (scrubguard) — every command this review ran, in order. Run from anywhere.
# SUBJ = the implementer's worktree (read-only; the guard is imported UNMODIFIED from it).
# SCR  = a private scratch dir; ORC = a private `git worktree add --detach $SCR/wt_oracle 9a230646`.
set -e
SUBJ=${SUBJ:-/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a196dcc5b08be6dc0}
SCR=${SCR:-/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r1_scrubguard}
P=$(cd "$(dirname "$0")" && pwd)
cd "$SCR"
# 1. the guard's verdict, gate semantics (USE_PCH=False, both configurations), controls first
python3 "$P/guard_fool_r1.py" "$SUBJ"                       > "$P/results/guard_fool_r1.txt"
python3 "$P/guard_fool_r1.py" "$SUBJ" N0 C5 A9 A10          > "$P/results/guard_fool_r1_batch2.txt"
# 2. does the BUILD compile each missed header (both configurations + a TU that USES the raw table)?
python3 "$P/build_compiles.py" "$SUBJ" "$SCR" A1           > "$P/results/build_compiles_A1.txt"
python3 "$P/build_compiles.py" "$SUBJ" "$SCR" A1b A2 A2b A3 A4 A4b A5 > "$P/results/build_compiles_batch1.txt"
python3 "$P/build_compiles.py" "$SUBJ" "$SCR" A9 A10       > "$P/results/build_compiles_batch2.txt"
# 3. INTRODUCED vs PRE-EXISTING: the same probes against the ORACLE guard (main 9a230646)
sed "s#$SUBJ#$SCR/wt_oracle#g" "$SUBJ/build/compile_commands.json" > "$SCR/cc_oracle.json"
mkdir -p "$SCR/wt_oracle/build/ir-pass" "$SCR/wt_oracle/build/runtime"
CQ_GUARD_COMPILE_COMMANDS="$SCR/cc_oracle.json" python3 "$P/guard_fool_r1_oracle.py" "$SCR/wt_oracle" "$SUBJ" \
    N0 A1 A1b A2 A2b A3 A4 A4b A5 A9 A10                     > "$P/results/guard_fool_r1_oracle.txt"
# 4. fail-closed / fail-open of the configuration and compile layers
python3 "$P/fail_open.py" "$SUBJ" "$SCR"                    > "$P/results/fail_open.txt"
