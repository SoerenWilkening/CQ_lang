# BRIEF_fix_c1b — the SECOND C-1 fix round (lens findings F-C1-1 and F-C1-2), bounded
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_fix_c1.md` (the first round's brief — its constraints 1–6
still bind), `$SP/progress/fix_c1.md` (what round 1 shipped), then `$SP/progress/review_c1.md` IN FULL (the lens
that found your two subjects; its reproducers are under `$SP/progress/review_c1_work/p/` and its instrumented
copy under `$SP/progress/review_c1_work/dbg/` — read its `[DBG]` output, do not re-derive from memory), then
`RETIRE_SWAP_ROUTE_INC1_NOTES.md` §2 ⭐ table + §3, and the code: `LoopLowering.cpp` (`peelInPlaceBase` /
`peelInPlaceStep` / `railValueConsumerDisposition` ~190–330; `tryCaseA`'s Case-A collapse; `collapseRailPhisIn`
step (3)'s `taint.InPlaceRailOps.insert(BO)` and step (4); `invariantRegisterRoots`; `collapseFlattenedLoopRails`
incl. the `AlreadyProcessed` block logic), `ArithLowering.cpp` (M-C: how a dtzb `add`/`xor` is chosen IN PLACE vs
OUT OF PLACE, the G6/G7 pair, and how `taint.InPlaceRailOps` is honoured — grep it: 21 hits in 5 files),
`TaintPropagation.h:370` (`InPlaceRailOps`), `TaintPropagation.cpp` (`repropagateControlMerges`, where the second
collapse is called and what snapshot it is handed). Agent name: `fix_c1b`. Model: opus.

## Where you work
The SAME worktree `$SP/wt/fix-c1`, branch `3qlq-inc1-fix-c1`, now at **ba01d8d** (3ec40c9 + a docs-only
commit). The lens is finished; the worktree is yours. Before you touch a source file, SAVE the round-1 binary:
`cp -f build/ir-pass/cq-opt $SP/progress/fix_c1b_work/cq-opt.fix1 && cp -f build/ir-pass/libCQPass.so
$SP/progress/fix_c1b_work/libCQPass.so.fix1` — that is "FIX-1" for your red-greens (the lens measured both
findings on it). PRE-FIX = main checkout 542d588 (never rebuilt). ORACLE = `$SP0/wt/pre-3qlq`. Extend the harness
with a `fix1` case pointing at the saved pair (the runtime archives are identical everywhere).

## F-C1-1 — CONFIRMED-MISCOMPILE: a PREHEADER in-place `add`/`xor` on the INVARIANT register re-opens C-1
```c
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  q = q + 7;                                     // the one added line (r71: q ^= 9)
  for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
```
FIX-1 and 542d588: rolled 3/0, unrolled 3/3, exit 0, STRICT 2b clean; the trace shows `cqrt_addc_i32(h0, 7)` —
the op IS lowered IN PLACE onto h0 by M-C — and then three undischarged `and_i32_hl(h0, …)` records through
`cqrt_ry_i32(h0, 0.9)`. ORACLE on the old-surface twin: rolled == unrolled, 38 = 38, `and_unc` 3. Measured cause
(`[DBG] IRR peel %4 = add nsw %2, 7 -> itself … IRR false: root not a CallInst`): `peelInPlaceBase(…,
AsLowered=true)` stops at the preheader `add` because `railValueConsumerDisposition` answers `Unproven` there
(a preheader is not `blockCanRepeat`, and `InPlaceRailOps` does not yet hold the op at collapse time), so clause
(ii) refuses and the whole extension fails. The (I1) proof carries verbatim; a PEEL precondition excludes the
customer. **Measure first, then fix:** (a) the same program WITHOUT `r` (pure-invariant, `NotClaimed` path) —
does it leak on FIX-1 / 542d588 too, and did the oracle discharge its old-surface twin? If yes, this is a
pre-existing F-L5-1-era hole, not round 1's, and the notes must say so. (b) the variant where the PRE-op value is
read AFTER the loop (`int keep = q; q = q + 7; … cq_measure(keep)`) — M-C must go OUT OF PLACE there (a template
rail, the Q-R1-1 class) and the extension must REFUSE it (leak-control, byte-identical to FIX-1).
THE FIX, Rule 14 first: the decision "will M-C lower this preheader dtzb op IN PLACE?" already exists in
`ArithLowering` (G6/G7: in place iff no later read of the pre-op value …). Do NOT write a second spelling of it.
Either (i) call that predicate from the peel at this stage (if it is callable before `lowerOps` — check what it
needs), or (ii) do what `collapseRailPhisIn` step (3) does for the BODY chain — prove the preheader op in-place
by the SAME rule and record it in `taint.InPlaceRailOps` so `AsLowered=true` peels through it AND M-C is then
COMMITTED to the same answer (one fact, both readers; verify M-C honours the set as a commitment, not a hint —
read the 21 hits). Then the 8h7d.5 question, in writing: what OTHER set is computed over `InPlaceRailOps`
(`staleRailRecordRead`, `declineStaleRecordOps`, `WireWalk`, `ArmClassify`'s uses, `railGateBetween`,
`collectRailGates`) and does recording a PREHEADER op there change any of their answers? Measure each with a
program. If neither (i) nor (ii) can be made sound in this round: the shape must NOT stay a silent leak — make
clause (ii)'s refusal on a dtzb `BinaryOperator` outside `L` a LOUD decline (`DiagnosticInfoUnsupported`, a
`cq loop lowering: …` string mirrored by a fixture) and write the OWNER QUESTION. Say which shipped.

## F-C1-2 — CONFIRMED-MISCOMPILE (twin witness): a mixed loop whose in-loop region is ONWARD (round 2) leaks
```c
int ext_f(int a);                                           // second TU: int ext_f(int a){ return a+100; }
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);                             // 6.5 arm -> %out, tainted only at ROUND 2
  for(int i=0;i<3;i++){ if((y>>i)&1) cq_phi(0.25); r=cq_theta(r,0.1); }
  y=cq_theta(y,0.9); return cq_measure(r)+cq_measure(y); }   // r35; r33 = the same without the diffusion
```
Both binaries: rolled 3/0, unrolled 3/3, `diff` = the three `_unc`+`free` pairs; exit 0; STRICT 2b clean.
Controls on FIX-1 (all 3/3): no carried register (`r34`), `r` gated outside the loop (`r50`), `r` carried by an
in-place `add` (`r51`), a 4.4 select-merge `%out` instead of the 6.5 one (`r72` — a tainted-condition select is
tainted at ROUND 1, so its region is a round-1 region). TWO causes, both measured by the lens:
* **(2a)** at round 1 the loop's control is CLASSICAL (the onward condition is untainted), so round-1
  `lowerLoops`' Case A collapses `r`'s phi itself; by the round-2 `collapseFlattenedLoopRails` there is no header
  phi, `collapseRailPhisIn` returns `NotClaimed`, and that branch calls `invariantRegisterRoots(…,
  CarriedRoots=nullptr)`, whose clause (iii) then refuses on the in-loop `cq_theta(%r0, .1)`. Round 1's clause (0)
  was wired to the `Collapsed` branch ONLY. FIX: the "already-claimed rail" fact must come from the TREE, not
  from the local `Roots`. Find what Case A and `collapseRailPhisIn` step (4) record (`InPlaceRailOps` holds the
  BinaryOperators; is there any record of a claimed ROOT or of the erased phi's chain?). If no fact exists, ADD
  ONE — `taint.ClaimedRailRoots` (or the right name), filled at BOTH collapse sites (Rule 14: one fact, two
  writers, one reader) — and make clause (0) consult the UNION of the local carried roots and that set. Do NOT
  infer "already claimed" from the absence of a header phi: an in-place gate whose result is dead in the body
  (`int t = cq_theta(r,.1);`) has no phi and no claim, and admitting it would be a wrong-multiplicity marking.
  Pin THAT shape as a control (does it decline today? measure).
* **(2b)** the extension can SUCCEED at round 1 (`r40`: a round-1 `r==3` kickback beside the onward one) and
  `markIfRailLocal` then bails `!AnyLocal` because the round-2 values are not yet tainted — and the loop is NEVER
  RE-OFFERED at round 2, because `AlreadyProcessed` / `InLoopFlattenedPreds` are sets of BLOCKS and the round-2
  flatten splices into the same pred block round 1 already flattened (measured: exactly one `[DBG] loop hdr=`
  line, `round2=0`, for `r40` and for `n8`). FIX: key the round-2 delta on something a round-2 region moves — the
  flattened region's own condition/branch identity, or a per-block counter, or simply RE-OFFER every touched
  loop at round 2 (the comment's worry — "a second mutation of a rail the first call already claimed" — must be
  MEASURED: `collapseRailPhisIn` on a fully collapsed loop finds no phi and returns `NotClaimed` without
  mutating; `markIfRailLocal` only grants; so a re-offer under round-2 taint is exactly the GRANT half of
  Q-R2-1). Choose with a measurement, record why, and note explicitly that this touches the once-only-stage
  table (notes §2 — add the row's new disposition). ⚠ Consequence for the record: notes §3.5's `n8` row and
  §3.7's `ControlOwnedRails` row are true of `n8` only because it also carries a ROUND-1 region; rewrite them.

## Also from the lens
* **F-C1-3** (`short q` → `-O1` hoists a `sext` into the preheader → a template rail → Q-R1-1's class): one
  sentence of disclosure in PRD E2 and notes ("… a cast the USER did not write — a `short`/`char` root is
  widened by `-O1`"), leak-control pinned if cheap (`r5_short_inv.c`).
* **F-C1-4**: notes §3.5's `d2`/`n4` rows print `0/0`; measured 3/0 | 3/3 (the condition is `i64`, so an
  `and_i32`-only grep read zero). Fix the two rows and say why they were wrong.
* **F-C1-7**: sub-grid F cannot see F-C1-1/2/3. Add cells for what a single-TU matrix CAN express: a PREFIX that
  puts an in-place `add`/`xor` on `a` BEFORE the loop (check whether the existing `PREFIX` axis has such a
  spelling — `addpre`? — and use it; sizes asserted; the 284 pre-existing generated sources byte-unchanged,
  proven by hash as round 1 did). The onward shape needs two TUs and is out of the matrix's reach — say so in the
  sub-grid comment and pin it in lit + e2e instead (below).

## Red-green (Rule 12) — RED on 542d588 AND on FIX-1, GREEN on yours
* `control_phase_kickback_mixed_preheader_addc_inloop.ll` (F-C1-1, r2's module; `UCNT-COUNT-3`; the `cqrt_addc`
  pinned in its own prefix), + the leak-control for the out-of-place variant (b) above (byte-identical to FIX-1),
  + a decline fixture if option (b)-decline shipped.
* `control_phase_kickback_mixed_onward_inloop.ll` (F-C1-2, r35's two-TU module `llvm-link`ed like
  `control_phase_kickback_onward_inloop.ll`), `…_mixed_onward_r1open_inloop.ll` (r40), + the dead-result
  in-place-gate control from (2a).
* e2e: `slice_control_phase_perbit_loop_mixed_preadd{,_unrolled}.c` + `cmp` gate (plain C, r2/r2u);
  `slice_control_phase_onward_perbit_loop_mixed{,_unrolled}.c` via `run_slice_multi.sh` (two TUs; follow the
  existing `slice_control_phase_onward_perbit_loop*` registration if one exists — `grep -n onward
  tests/e2e/CMakeLists.txt`) + `cmp` gate — ⚠ the lens's OQ-C1-3 / bd 3qlq.9 says the FLAT twin of a mixed
  onward loop DECLINES `control flow under quantum control` on both binaries. MEASURE r35u/r33u on your binary
  first; if the flat twin declines, there is no `cmp` gate to add — register the rolled slice alone, STRICT 2b,
  with the header saying exactly why it has no twin (and which bd issue owns that), and make the lit fixture
  carry the LIFO per-trip pairing assertion instead.
* All goldens by the full pipeline, STRICT 2b.

## Verification you owe (only what you ran, commands in the progress file)
Red-green per fixture on three binaries (542d588 / FIX-1 / yours) · the ENTIRE population of round 1 (§3.5) +
the lens's 60 programs re-run on yours: nothing already IDENTICAL may move (byte-diff every rolled trace vs
FIX-1 — the only traces allowed to change are the F-C1-1/F-C1-2 populations, list them) · the Q-R1-1 controls
(`n9`, `d2`, `d3`, `n4`, `r5`) still leak byte-identical · mutation validation one half at a time for EACH of
the two fixes (4 cycles) · `ctest -R ir-pass-lit` background → 0 reds outside your new files · the perbit /
onward / mixed slices + all `*-twin-identical` gates + `e2e-loop-twin-quarantine-selftest` · the matrix in the
background (`--regenerate` for the new cells; any DIVERGENCE is a finding, never a quarantine) · the injection
matrix over your new accepts (0 MISSED / 0 DIRTY, clean + known-bad controls) · STRICT 2b everywhere.
Docs: notes **§3.10** (this round: the two findings, root causes, fixes, the 8h7d.5 table for `InPlaceRailOps`
and for the round-2 re-offer, the corrected §3.5/§3.7 rows, the once-only-stage table row); PRD §0 E2 (the
list of what the fix does not cover, again — after this round the only residual should be Q-R1-1's template
rails incl. the `-O1`-widened `short`); CLAUDE.md's one C-1 sentence gains a clause naming these two; the
count lines in CLAUDE.md/ROADMAP (lit / ctest / matrix) re-measured by command. Commit per logical step, hand
back per BRIEF_common: first line = which option shipped per finding and the r2 / r35 / r40 rolled/unrolled
`and_unc` counts on your binary.
