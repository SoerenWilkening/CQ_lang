# Merge-and-gate brief — landing 2: Track R increment R-1 (bd `rb9x`, branch `rb9x-f2-clones`)

Instance of `../MERGE_BRIEF_TEMPLATE.md` (read it first; every step applies). Model: opus. Worktree
`/Users/sorenwilkening/Desktop/CQ_rb9x`, branch `rb9x-f2-clones` (base 81956a2; review r1 verdict
**CLEAR-WITH-ITEMS**, `review_R1_r1.md`), merging `main` at `git -C /Users/sorenwilkening/Desktop/CQ_lang
log -1 --format=%h` = **23b0cd1 = landing 1 (Track C `MeasureLowering.{h,cpp}` + 8 fixtures + 6 slices +
`tests/e2e/CMakeLists.txt`)**. Expect a `tests/e2e/CMakeLists.txt` add/add conflict (both sides appended
registrations) — resolve by KEEPING BOTH blocks in order (landing 1's, then this track's); expect NO
`ir-pass/src` conflict (disjoint files: C touched only `MeasureLowering`; R touched `TaintPropagation.h`,
`MergePhiPeel.cpp`, `ArmClassify.cpp`) — if one appears, STOP and report. `$SES/trackR/GATES.md` may
conflict add/add with main's copy (the scoping+audit lines) — take the UNION in order. You are the ONLY
full-`ctest` runner right now.

## Landing-specific items (step 8), BEFORE step 3

A. **Apply the review's comment-only items** (no string, no predicate change):
   1. R1r1-1: the two-diamond fixture's header (the one with the bd `35t0` retirement trigger): keep "the
      day `35t0` closes this becomes an ACCEPT" and DROP "the preimage-vs-wire distinction becomes
      load-bearing"; add the reviewer's second argument (a foreign clone's ORIGINAL is tainted, a user of the
      same operands, folds identically — so either the original still collides or it is in `CondWire`;
      probes `review_R1_r1_probes/td3_valueB.ll`, `td2_pad.ll`).
   2. R1r1-3: `control_peel_stateprep_datamux_peeled_control.ll`'s `CPCNT-COUNT-3: @cqrt_copy_` counts 2
      calls + 1 `declare` — relabel the comment (do NOT change the count or the prefix).
B. `cq-opt-equivalence-full`: **OWED** (an analysis site changed: `ArmClassify.cpp` F2's test).
C. Corpus: the implementer's 2949-row sweep is a fact about `221c1caa465db61e`; the merged binary carries
   landing 1's source too ⇒ run the sweep ONCE on the merged binary over ALL corpora the template names
   PLUS `$SES/trackR/review_R1_r1_probes`, `$SES/trackC/*probes*`, `$SES/trackL/probes`. Expected movers vs
   ORACLE: DECLINE→ACCEPT on F2's string (R-1) and on `operand not recognized` (landing 1); 2 F2→later-fence
   (`R2_p80_window`, `R4_p80_measured`); 0 ACCEPT→DECLINE; 0 both-accept circuit changes.

## Customers (step 7)

* `$SES/trackR/probes/b_A_intb0_boolb1.c` (the `rb9x` program): exit 0, **22 lines** = the committed golden
  `slice_control_stateprep_bool_under_int_compare_fused.expected.log`.
* `$SES/probes/va.c`: 19 lines = `va.trace`. `$SES/trackC/probes/owner_2026-09-11_2218.c`: 15 lines.
* `$SES/probes/owner_file_2026-09-13.c`: expected DECLINE `control flow` (Track M). `$SES/probes/vd.c`:
  expected DECLINE F2 (R-2 not built) — record both.

Record `$SES/trackR/MERGE_R1_1.md` in the worktree + `GATES.md` lines. Final message per the template.
