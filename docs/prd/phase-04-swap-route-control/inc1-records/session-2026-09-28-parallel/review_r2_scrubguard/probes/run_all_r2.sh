#!/bin/sh
# Review r2 (scrubguard) — every command this review ran, in order. -j4 max (CQ_GUARD_JOBS=4).
# SUBJ = the implementer's worktree (read-only; the guard is imported UNMODIFIED from it).
# SCR  = a private scratch dir holding three PRIVATE worktrees:
#   $SCR/wt      = git worktree add --detach a5cab4f7   (subject commit; its REAL tree is mutated by tree_probes_r2.py)
#   $SCR/wt_r1   = git worktree add --detach 223685ac   (round 1 of the rewrite, guard sha 99a7df7c)
#   $SCR/wt_main = git worktree add --detach 9a230646   (main, the pre-rewrite guard, sha d2686266)
# each with the subject's compile_commands.json rewritten to it: sed "s#$SUBJ#$SCR/<wt>#g" > $SCR/cc_<wt>.json
set -e
SUBJ=${SUBJ:-/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a196dcc5b08be6dc0}
SCR=${SCR:-/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rev_r2_scrubguard}
P=$(cd "$(dirname "$0")" && pwd); R=$P/results
export CQ_GUARD_JOBS=4
cd "$SCR"
# 1. does the BUILD compile every probe header (both configurations + a TU that writes into the raw table,
#    and -E of real TUs for the include-order probes)?
python3 "$P/build_compiles_r2.py" "$SUBJ" "$SCR"            > "$R/build_compiles_r2.txt"      # (its B9 row is superseded by the next line)
python3 "$P/build_compiles_r2.py" "$SUBJ" "$SCR" B9 B6      > "$R/build_compiles_r2_B9_B6.txt"
python3 "$P/build_compiles_r2.py" "$SUBJ" "$SCR" B11        > "$R/build_compiles_r2_B11.txt"
# 2. the subject guard's verdict, gate semantics (USE_PCH=False, both configurations, include-order check), controls first
python3 "$P/guard_fool_r2.py" "$SUBJ"                        > "$R/guard_fool_r2.txt"
python3 "$P/guard_fool_r2.py" "$SUBJ" B11                    > "$R/guard_fool_r2_B11.txt"
# 3. fail-open of the NEW include-order check (a wrapper compiler misbehaving only on its two -E TUs)
python3 "$P/fail_open_r2.py" "$SUBJ" "$SCR"                  > "$R/fail_open_r2.txt"
# 4. the gate's own CLI on a REAL mutated tree (subdirectory header, .def X-macro), private worktree
python3 "$P/tree_probes_r2.py" "$SCR/wt" "$SCR/cc_wt.json"   > "$R/tree_probes_r2.txt"
# 5. INTRODUCED vs PRE-EXISTING: round-1 guard and main guard
CQ_GUARD_COMPILE_COMMANDS=$SCR/cc_wt_r1.json   python3 "$P/guard_fool_r2_cmp.py" "$SCR/wt_r1" r1 N0 B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11 > "$R/cmp_round1_guard.txt"
CQ_GUARD_COMPILE_COMMANDS=$SCR/cc_wt_main.json python3 "$P/guard_fool_r2_cmp.py" "$SCR/wt_main" main N0 B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11 > "$R/cmp_main_guard.txt"
CQ_GUARD_COMPILE_COMMANDS=$SCR/cc_wt_main.json python3 "$P/cmp_main_extra.py" "$SCR/wt_main" B1 B2 B7 B8 > "$R/cmp_main_guard_extra.txt"
