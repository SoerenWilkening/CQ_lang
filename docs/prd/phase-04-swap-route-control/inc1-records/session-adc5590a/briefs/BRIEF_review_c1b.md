# BRIEF_review_c1b — ONE narrow Rule-13 lens on the SECOND C-1 fix round (F-C1-1 / F-C1-2), READ-ONLY
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_fix_c1.md`, `$SP/briefs/BRIEF_fix_c1b.md` (what the two fix
agents were asked), `$SP/progress/fix_c1.md`, `$SP/progress/review_c1.md` (the lens that found F-C1-1/2 — its
reproducers under `$SP/progress/review_c1_work/p/`, its instrumented copy under `…/dbg/`), then
`$SP/progress/fix_c1b.md` IN FULL, and `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3 incl. the new §3.10.
Agent name: `review_c1b`. Model: opus. READ-ONLY on every checkout (write only under `$SP/progress/review_c1b_work/`).

## Binaries (name every path you use)
- SUBJECT (fix round 2): `$SP/wt/fix-c1` at 638334c — build current (verify with `find … -newer`).
- FIX-1 (fix round 1, 3ec40c9's binary): `$SP/progress/fix_c1b_work/{cq-opt.fix1,libCQPass.so.fix1}` (saved by
  fix_c1b before it rebuilt; the runtime archives are identical everywhere).
- PRE-FIX: main checkout `/Users/sorenwilkening/Desktop/CQ_lang` at 542d588 (never rebuilt).
- ORACLE: `$SP0/wt/pre-3qlq` (52d7764, old-surface twins only).
Control the harness with a clean run and a known-bad run before trusting a number.

## Your questions — each answered by a MEASUREMENT or an argument you performed
1. **F-C1-1's fix, adversarially.** Whatever mechanism shipped (a call into M-C's in-place predicate from the
   peel, a `taint.InPlaceRailOps` commitment for the preheader op, or a loud decline): (a) is the answer the peel
   now gets ALWAYS the answer `lowerOps` later gives? Construct programs where M-C must go OUT OF PLACE (the
   pre-op value read after the loop; read inside the loop; read by a tape write; two preheader ops in a chain
   with the middle value read; a preheader op whose classical operand is a run-time value; an `xor` then an
   `add`; a preheader op on the CARRIED register instead) and confirm each is either discharged with the op in
   place (rolled == unrolled) or refused (leak-control byte-identical to FIX-1) or declined loudly — NEVER
   admitted as a root while M-C lowers the op out of place (that is the K-adjoints-of-one-gate multiplicity
   defect: look for any `_unc`/`_inv` in the body whose forward is outside the loop). (b) The 8h7d.5 question
   for `InPlaceRailOps` if it gained a preheader member: re-run `declineStaleRecordOps` / `staleRailRecordRead`
   / `WireWalk` / `ArmClassify` R6 probes with the preheader op present — any decline that disappeared, any
   accept that appeared, vs FIX-1.
2. **F-C1-2's fix, adversarially.** (2a) the "already-claimed rail" fact: is it written at BOTH collapse sites
   (Case A in `tryCaseA`, `collapseRailPhisIn` step (4)) and read at ONE place? Construct: the dead-result
   in-place gate (`int t = cq_theta(r,.1);` in the body, `t` unused) — must NOT be treated as claimed; a rail
   claimed at round 1 whose chain is then extended at round 2; two carried rails, one claimed by Case A and one
   by the round-1 collapse. (2b) the round-2 re-offer: whichever keying shipped, construct a loop with TWO onward
   regions in one body, an onward region in a loop whose round-1 region was DECLINED, an onward region in a
   NESTED loop (must decline), and a round-1-collapsed loop with no onward region at all (must be byte-identical
   to FIX-1 — the re-offer must be a no-op there). Confirm no double mutation: `collapseRailPhisIn` on a fully
   collapsed loop returns `NotClaimed` and mutates nothing (read the code and measure with a `[DBG]` copy if you
   need one, in YOUR scratch copy only).
3. **The whole population, re-run**: round 1's §3.5 table + the review_c1 60 programs + fix_c1b's new ones, on
   FIX-1 and on the subject; every trace that was IDENTICAL on FIX-1 must be byte-unchanged; the only moved
   traces are the F-C1-1/F-C1-2 populations (list them); the Q-R1-1 controls (`n9`, `d2`, `d3`, `n4`, `r5`)
   still leak byte-identical. Then ≥ 10 NEW spellings of your own around the two fixes.
4. **Red-green and record truth, briefly**: each new fixture RED on 542d588 and on FIX-1 / GREEN on the
   subject; the mutation cycles reproduce (on a scratch copy only); the notes §3.10 numbers reproduce; the
   corrected §3.5/§3.7 rows are now true; the once-only-stage table row for the re-offer is true of the binary;
   the matrix's pre-existing generated sources byte-unchanged.
Grade: `CONFIRMED-MISCOMPILE` / `LEAK` / `OVER-DECLINE` / `DOC` / `CLEAR`. Write `$SP/progress/review_c1b.md`
(findings F-C1B-k, reproducers under `$SP/progress/review_c1b_work/`, what you ran, verdict line
`CLEAR` / `CLEAR-WITH-ITEMS` / `FINDINGS`). Return it as your final message.
