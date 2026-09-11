# Rule-13 review brief, round 2 — bd `b6ap` (multi-phi merge peel), reviewing the round-1 FIX

Worktree `/Users/sorenwilkening/Desktop/CQ_b6ap`, branch `merge-phi-peel`, `build/` current (do NOT
rebuild; do NOT edit `ir-pass/`, `include/`, `tests/`, `tools/`). Read in order: `review_b6ap_r1.md` (the
BLOCK), `FIX_BRIEF_b6ap_R1.md`, `FIX_b6ap_R1.md` (what was built), then `IMPL_b6ap.md`, `SCOPE_b6ap.md`.
ORACLE `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` + `libCQPass.so` (read-only). Gates
already run on the fix: `ir-pass-lit` 1811/1810+1 XFAIL; `^e2e-` 379/379; full `ctest -j6` 389/389
(1318 s loaded); `cq-opt-equivalence-full` 1811 / 0 mismatches; corpus diff 1776 `0/0/0`. Re-run
`ir-pass-lit` and any single entry you touch; not the full suite.

## What the fix did

* F-B6-1: `peelIndependentMergePhis` now RETURNS its taint delta (`propagateFromSeeds` fills it); both
  round-1 sites (`CQLoweringPass.cpp:441`, `:919`) pass it to the new `adjudicateTaintDelta` — the four-call
  sequence lifted VERBATIM from `repropagateControlMerges` (which now calls it too; one spelling). Position
  (b) kept — (a) was refused per stage: the loop prepasses re-run the PredMux fixpoint internally and
  PredMux's W-witness is `NumMergePhis >= 2`; `lowerControlledIOSinks`' gate is `NumPhis == 0 || ValuePhi`;
  `lowerLoops` is P9's neighbourhood. A SIXTH reproducer (`k01`: `helper(a,m)` already a `Pending` Phase-6
  candidate, so `declineTaintEscapes` CARVES it and only `replanReseedSpecialization` stops the clone
  reading the rail as `cq_template_add_i32_hl(h1, 4)`) — mutants M-A/M-B/M-C pin three of the four calls;
  M-D (`declineStaleRecordOps`) has NO measured customer and is an open question.
* `r20` is an ACCEPT on purpose: lowered IR + trace byte-identical to the ORACLE's lowering of the
  hand-peeled twin `r23`.
* F-B6-2: new clause P10 `armWritesMemory` — `g01` keeps `guarded store with a merge value`, `g02`
  byte-identical to the oracle.
* DOC: D1's reason rewritten (measured `d01`/`d02` same unitary); P3b `freeze` argument + fixtures; the
  matrix header caveat + "re-derive, never regenerate" tripwire.
* Noted: a decline STRING can move within the decline class (`f02` now declines at the escape net, earlier
  owner, same disposition).

## Where to look (attack the FIX, then re-attack the increment through it)

1. **Delta completeness.** `propagateFromSeeds` fills the delta from the peeled selects — is the delta the
   FULL forward closure that `propagateWorklist` would have produced from the same seeds at `propagate()`
   time (phis, selects, casts, calls, stores, GEPs, the by-ref math markers, `freeze`, `llvm.*`
   intrinsics)? Construct a consumer of a peeled select that `propagateFromSeeds` does NOT reach but the
   original propagation would have (a user through a `phi` in a later block; a `store` whose pointer is
   tainted; a curated intrinsic; a `switch` on the select; a call argument to a Pending candidate — the
   `k01` shape — with the select two hops away). Any such consumer is F-B6-1 re-opened.
2. **`adjudicateTaintDelta` is four calls; are those the only consumer-adjudicating stages that ran
   before `:441`?** Walk `CQLoweringPass::run` from `propagate()` to `:441` and list EVERY stage that reads
   `taint.Tainted` to make a decision about a consumer (the QRAM/Shadow provenance walk, `lowerByRefMath`'s
   plan, the IO-sink lowering, `declineClassicalMuxes`, `LiteralIntegrity`, the loop prepasses'
   taint-dependent gates, `declineUnpairedUndefLiterals`) — for each, either it runs AFTER `:441` (say so
   with the line), or it is in the four, or it is a HOLE: construct the customer. This is the NOTES §2
   method; write the table into your report.
3. **M-D.** `declineStaleRecordOps` has no measured customer in the delta. Build one: a peeled select
   whose ARM incoming is a tainted value defined BEFORE the region and whose wire carries a later
   non-diagonal gate (the stale-record class) — does the peel create a stale reader the guard should
   refuse, and does the re-run refuse it? If no program can reach it, say why (structural), and whether
   the call can be dropped or must stay as a tripwire.
4. **`r20` byte-identity claim.** Re-run `r20` on the subject and `r23` on the oracle and `diff` the lowered
   IR (not only the trace); then vary: `helper` with two tainted args, `helper` returning void, `helper`
   `noinline` vs inlinable, the measure on `handle+1` vs on the helper's result.
5. **P10 `armWritesMemory`.** What counts as a write: a `StoreInst` in the arm; a call to a function that
   writes (a QRAM marker; `memset`; a by-ref libm call; an `@llvm.memcpy`); a store in a block the arm
   DOMINATES but outside it? Construct the guarded-store shape through each and confirm the decline holds.
6. **Round 2 sites.** `repropagateControlMerges` now calls `adjudicateTaintDelta` too — twice per round
   or once? Is the peel's round-2 delta (site 3 inside the fixpoint loop) adjudicated on EVERY iteration?
   A round-2 peel whose select feeds a round-3 region.
7. **The string move (`f02`).** Same disposition, earlier owner — confirm the class is unchanged on every
   pre-existing decline fixture (`DIAGDIFF=0` says yes for the 1776; probe the reviewer's r1 corpus and
   the implementer's probes for string moves and list them).
8. **Re-attack the angle boundary through the fix**: a peeled ANGLE select whose consumer `cq_phi` is in a
   function that `replanReseedSpecialization` now clones — does the clone carry the select and re-classify
   it correctly, or is the angle orphaned in the clone (the P7 class)?

## Method

Scratch `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/b6ap_review2/`;
plain C `-O1` first, hand IR second; both binaries; state-vector arguments; grade
CONFIRMED-MISCOMPILE / OVER-ACCEPT-ARGUED / OVER-DECLINE / LEAK / DOC; verdict BLOCK / CLEAR-WITH-ITEMS /
CLEAR. Report `session-b6ap/review_b6ap_r2.md`, probes `session-b6ap/review_b6ap_r2_probes/` with a
runner. Final message ≤30 lines: verdict, findings one line each with grade, the stage-table outcome
(item 2), the M-D outcome.
