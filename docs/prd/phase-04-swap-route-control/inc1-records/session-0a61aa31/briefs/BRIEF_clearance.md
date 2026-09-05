# BRIEF_clearance — Rule-13 CLEARANCE review of Inc 0 + Inc 1 (register-free `cq_phi` by kickback), whose VERDICT decides the commit
Read `$SP/briefs/BRIEF_common.md`, then the PRD (§1–§6, §10–§12), then in order: `$SP/progress/impl_inc1a.md`,
`$SP/progress/impl_inc1b.md`, `$SP/progress/fix_r1.md`, `$SP/progress/fix_r2.md`, the round reports
`$SP/progress/review_r1_L{1..8}.md`, `$SP/progress/review_r2_R{1,2}.md`, the notes
`docs/prd/phase-04-swap-route-control/RETIRE_SWAP_ROUTE_INC1_NOTES.md` (§1, §2), `$SP/progress/OWNER_QUESTIONS.md`,
and the three follow-up hand-backs `$SP/progress/prep_a2.md`, `prep_b2.md`, `prep_d2.md`.
Agent name: `clearance`. READ-ONLY.

## Subject
The main checkout `/Users/sorenwilkening/Desktop/CQ_lang` at be4e2ea — Inc 0 (docs + `cq_ry`) + Inc 1
(surface, P1–P7, round-1 + round-2 fixes) + the merged follow-ups (migrated fixtures, rewritten slices +
regenerated goldens, twin-matrix tables); `build/` current. ROUND-1 SUBJECT `$SP/wt/r1-subject` (fa96336);
ORACLE `$SP/wt/pre-3qlq` (52d7764). The FULL `ctest -j6` result will be in `$SP/progress/orch_full_ctest.log`.

## What a clearance review is
Not a ninth lens. You decide whether THIS change may ship, on three questions, each answered with a measurement
or an analytic argument you performed yourself (re-run what you cite; do not trust hand-backs):
1. **Is there any path on which the emitted circuit is a different unitary from the source's, at `opt` exit 0?**
   Re-attack the three confirmed classes of the two rounds with NEW spellings (the spine adjoint on the shared
   flag; the round-2 onward claim vs once-only stages — F-L3-1 and F-R1-1 are the SAME shape and there may be a
   third instance; the retired-family third path; the in-loop discharge for invariant registers incl. the
   hoisted-template residual Q-R1-1) and the 8h7d.5 question at every fix: "which OTHER set was computed over
   the closure this fix narrowed?" Then the shapes no lens owned: kickback + 7.6 tape write in one arm; kickback
   inside a Bennett-wrapped clone's CALLER arm; kickback whose flag feeds a QRAM index; a kickback region whose
   pred is another region's merge (hcrg) inside a loop; P3 with a leaf that is a loop-carried phi; P5 with a
   case arm that is a kickback + the same case value in a nested P1; the D4 per-bit idiom followed by the
   diffusion at K=4 and K=32 with rolled==unrolled byte identity; `cq_phi` in a function called from BOTH a
   classical and a tainted context (Phase-6 (callee,mask) cache).
2. **Does anything free a rail that is not provably |0⟩, or leave a rail dirty where the oracle discharged it?**
   Stage 2b STRICT on every reproducer; the rolled/unrolled and nest/&& twin gates; the golden audit
   (`tools/golden_multiset_audit.py --epic 3qlq --rev 52d7764`) over the regenerated goldens — every diff one of
   (a)–(d) or a listed REWRITTEN PROGRAM; the void loop twin matrix green with its quarantine additions each
   carrying a bd issue; the 15 keep-alive rewrites really exercising the `_unc` they claim (read three traces).
3. **Is every accept pinned and every decline mirrored, and does the record tell the truth?** Sample ≥40 accepts
   with an injection set (L8/R2 harnesses are under `$SP/progress/review_r1_L8/` and `review_r2_R2/`) — every
   injection caught; the notes' counts re-measured; the PRD's §2 decisions honoured (D1–D7) and every §12
   assumption still consistent with what shipped; the CLAUDE.md/docs claims true of the binary.

## Verdict (last line of your report, exactly one of)
`CLEAR` · `CLEAR-WITH-OWNER-QUESTIONS` (list them) · `BLOCK` (the finding, the reproducer, the two traces).
A BLOCK needs one reproducer with a wrong unitary or a dirty free; an unpinned accept or a false sentence is a
CLEAR-WITH-OWNER-QUESTIONS item unless it hides a wrong unitary. Write `$SP/progress/clearance.md`; return it.
