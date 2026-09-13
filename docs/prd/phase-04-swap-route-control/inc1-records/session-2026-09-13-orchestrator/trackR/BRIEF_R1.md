# Brief — Track R IMPLEMENTATION, increment R-1: F2 excludes the peel's compare CLONES via a `taint.PeelClones` RECORD — bd `rb9x`

Written 2026-09-13 by the orchestrator after `SCOPE_R.md`. Model: opus. Worktree
`/Users/sorenwilkening/Desktop/CQ_rb9x`, branch `rb9x-f2-clones` (fast-forwarded to `main`, the commit that
carries `SCOPE_R.md`), its OWN `build/` (`cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm
-DCMAKE_BUILD_TYPE=Release && cmake --build build -j8` — BOTH targets, always). Protocol: `../PROTOCOL.md`,
row "implementation" (inner loop = `lit --filter` + single slices; `ir-pass-lit` ONCE at hand-off; corpus
sweep ONCE → `probes/corpus_<hash16>.txt`; injection matrix ONCE; NO `^e2e-`, NO full suite, NO equivalence
sweep). Append to `GATES.md` (hash-keyed; the scoping line is there). Record `IMPL_R1.md` beside this file.
Do not commit, do not push. Never write outside your worktree. Report only what you ran (`cited:`/`ran:`).

## 0. Read first

`SCOPE_R.md` — ALL of it: §1.1 the ROUTE (four steps, `ArmClassify.cpp:1505-1510` / `:1549-1553` /
`:1619-1626` / `:1198-1208` / `:1616`), §2 R-1's design and the **preimage** argument (NOT the "same wire"
one — §3b says why), §3a the TRAP (a dominance conjunct re-opens ≥11 pinned holes — refuse it in writing),
§3e (`r_R4` stays a DECLINE after R-1, by design — the exclusion is at the TEST, the clone is still popped
and its users modelled), §3f the corrected `MergePhiPeel.cpp` paragraph to PASTE, §4 the partition, §5 the
fixtures; `probes/README.md` + `probes/run.sh`. Then `CLAUDE.md` (Prime Directive; Rules 1, 12, 13, 14, 17,
19; CORRECTNESS RISK §2 "F1 / F2", §3 L1/L5/L8, §4 "what the F2 narrowing silently absorbs" with its
RETIREMENT TRIGGERS), `../../session-f2-i1/IMPL_f2.md` (how F2's 2026-09-11 conjunct was landed — the
precedent for one-conjunct-at-the-test), `bd show rb9x`.

## 1. Scope — R-1 ONLY

IN: (1) `peelIndependentMergePhis` records every clone it manufactures in a new `TaintSet` field
`PeelClones` (`SmallVector<WeakTrackingVH>` or a `WeakTrackingVH`-keyed set — a RAW `Value *` is the l4x4.b
H-1 defect: the clone is erased by `lowerOps`/`SelectMergeEmit`, and a freed pointer must never answer
`count()`), written at `MergePhiPeel.cpp:491` beside `taint.Tainted.insert(Clone)`; (2)
`f2SeedPinnedByLiveRegister` consults it as ONE more conjunct at the ONE place `CondWire` is consulted
(`ArmClassify.cpp:1616`) — **at the TEST, never at the anchor, never pruning the users walk**
(`control_peel_reject_fp_stateprep.ll` is the red-green witness: pruning the walk flips a deliberately
pinned fp-mux decline into an unargued accept; it must stay a DECLINE, and it gets a RETIREMENT-TRIGGER
header line naming R-1); (3) the `MergePhiPeel.cpp:454-469` comment replaced by SCOPE §3f's paragraph
verbatim; (4) the argument written in the source at BOTH sites as the **preimage** one ("a value this pass
MANUFACTURES has no source preimage and therefore no rival program for F2 to protect against"), with the
retirement triggers of SCOPE §2 R-1 (F2's own at `:1283` + the two peel-shape triggers). OUT: **R-2** (`vd`'s
collider — a separate increment, its own bd and rival audit, do NOT fold it in); any dominance/position
conjunct (§3a); any name- or structure-based spelling of "a clone" (§2 spelling (ii), refused; the
hand-written `%cq.peel.cond` in `control_peel_stateprep_datamux_peeled_control.ll` must NOT acquire the
exclusion — pin that it is untouched).

L1 obligation: the peel runs before ALL THREE `detectControlRegions` sites and F2 runs inside `classifyArms`
in BOTH rounds — the record is populated by the peel itself in both rounds by construction, must NOT be
cleared between them, and a round-2 clone is ADDED. Say in IMPL_R1.md §1 which stage could clear a
`TaintSet` field between rounds and confirm none does.

## 2. Rule 12 — red-green, in this order

1. DECLINES first, RED on the ORACLE for the right reason and KEPT after R-1 (mirror
   `state prep seed is proven equal to the condition register under quantum control` character-for-character):
   `r_R1b`/`r_R5` (a second tainted compare on the wire that is NOT a clone — the fixture that stops R-1 from
   being widened into "any second compare"); `r_R4` (the `zext` of a pinned flag vs an `i32` seed — stays a
   DECLINE, §3e, header says why); `…_second_flag_i1.ll` gets a retirement-trigger header line only;
   `control_peel_reject_fp_stateprep.ll` gets a retirement-trigger header line only (no RUN/CHECK change).
2. ACCEPTS: the `rb9x` shape as `-O1` produces it (`probes/b_P2_intcmp_i1seed_peeled.c` stage-1 IR → a
   fixture modelled on `control_inplace_ry_stateprep_bool_seed_int_cond.ll`: full positive `CHECK`s for the
   stream — `cqrt_alloc_i1` + `cqrt_ry_i1_controlled` + the peeled mux's copies — pure whole-file negative
   prefixes and `ACNT/FCNT/XCNT/RYCNT/CCNT` counts); seed `true` (`b_P2t`); the hand-IR clone family
   `b_HP_{a,c,d,e,g}` (at least `HP_g_sel_only` and `HP_c_merge` as fixtures — RED on the ORACLE at F2, GREEN
   here); the two-diamond shape of §3b (two fused diamonds, two clones; the second clone pinned on the first
   region's edge — an ACCEPT under the preimage argument; write the argument in the fixture header).
3. Injection matrix over the accepts: an injected uncontrolled `cqrt_ry` on the CONDITION register after the
   flag's free; an injected `cqrt_x` on a user register; an extra `cqrt_free`; the `_controlled` gate's
   control/target swapped; the peeled mux's two copies swapped. Report MISSED per fixture.
4. e2e (STRICT 2b): `tests/e2e/slice_control_stateprep_bool_under_int_compare_fused.c` = the `rb9x`
   program `probes/b_A_intb0_boolb1.c` (`int b0`/`bool b1`/`int a`); golden COMPOSED from `b_C`'s 22 lines
   with the b1 rail at `i1` widths, then MEASURED on your binary — never commit a composed golden unread.
   Register after the last `slice_control_inplace_ry_*` group; `ctest -R '^e2e-slice-<name>$'`.

## 3. Record: `IMPL_R1.md`

§0 measured before coding (SCOPE §0's 36 rows on your UNMODIFIED build = ORACLE); §1 the field, the insert,
the conjunct (`file:line` before/after, verbatim) + the round-2 clearing question; §2 the two comment
rewrites (paste); §3 red-green log; §4 injection matrix; §5 e2e; §6 corpus sweep ORACLE-vs-SUBJECT (movers
must be DECLINE→ACCEPT on F2's string ONLY, each listed — in particular every `control_peel_*`/`stateprep`
fixture that does NOT move); §GATES; §7 open questions / found-in-passing.

Final message ≤30 lines: the three sites, the round-2 answer, the rb9x slice trace (22 lines? measured),
movers by string, GATES.md verbatim, §7.
