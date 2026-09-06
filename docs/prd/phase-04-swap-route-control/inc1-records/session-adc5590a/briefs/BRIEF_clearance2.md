# BRIEF_clearance2 — Rule-13 RE-CLEARANCE of 3qlq Inc 0 + Inc 1 after the C-1 fix round; the VERDICT decides the landing on main
Read `$SP/briefs/BRIEF_common.md`, then the previous clearance IN FULL —
`docs/prd/phase-04-swap-route-control/inc1-records/session-0a61aa31/clearance.md` (its BLOCK, its population,
its §4 unpinned surfaces and §5 owner questions) and its brief `briefs/BRIEF_clearance.md` (the three questions;
they are yours again) — then `$SP/progress/fix_c1.md`, `$SP/progress/review_c1.md` (the lens on fix round 1 — verdict FINDINGS: F-C1-1 a preheader in-place `add` on the invariant register, F-C1-2 the mixed loop whose region is ONWARD), `$SP/progress/fix_c1b.md` (fix round 2), `$SP/progress/review_c1b.md` (the lens on it — verdict FINDINGS: F-C1B-1 a CONFIRMED miscompile INTRODUCED by round 2, a preheader in-place commit taken under round-1 taint and honoured after round-2 taint growth, a quantum handle in `cqrt_addc`'s immediate slot; F-C1B-2 a module-wide claim key for a per-loop property), `$SP/progress/fix_c1c.md` (round 3, the NARROWING: `isa<Constant>` immediate at commit + a loud lowering-time tripwire + a per-loop claim key) and `$SP/progress/review_c1c.md` (the lens on round 3),
`RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3, the PRD §0 ERRATA (E2 rewritten), and the bd issues the orchestrator filed
this session (`bd show test_C_libtooling-3qlq` — the four new children on the interleaved-region over-decline,
OQ-29, OQ-21, Q-R2-1/3). Agent name: `clearance2`. READ-ONLY (you may write under `$SP/progress/clearance2_work/`).

## Subject
`$SP/wt/fix-c1` at da743dc (Inc 0 + Inc 1 + the migrated corpus + all THREE C-1 rounds; FIX-1 = 3ec40c9's binary at `$SP/progress/fix_c1b_work/*.fix1`, FIX-2 = 638334c's at `$SP/progress/fix_c1c_work/*.fix2`), build current
(verify with `find … -newer build/ir-pass/cq-opt`). PRE-FIX = the main checkout at 542d588 (the previous
clearance's subject + two docs commits; build current). ROUND-1 SUBJECT `$SP0/wt/r1-subject` (fa96336).
ORACLE `$SP0/wt/pre-3qlq` (52d7764). The orchestrator's FULL `ctest -j6` on the subject will be in
`$SP/progress/orch_full_ctest_final.log` — wait for it (poll) before your §1 table; do not run it yourself.
The previous clearance's harness and 96 reproducers are under `$SP0/progress/clearance_work/`; reuse them
(re-point `run.sh` at the subject).

## What a clearance review is (unchanged)
Not another lens. You decide whether THIS tree may land on main, on the same three questions, each answered
with a measurement or an analytic argument you performed yourself (re-run what you cite; the previous
clearance's CLEAR items are re-checked by SAMPLING, its BLOCK by everything you have):
1. **Is there any path on which the emitted circuit is a different unitary from the source's, at `opt` exit
   0?** THE BLOCK FIRST: C-1's population (clearance.md §2.2) rolled == unrolled on the subject, byte-identical,
   every member and every new spelling from fix_c1, review_c1, fix_c1b, review_c1b, fix_c1c and review_c1c (incl. the four F-C1B-1 reproducers, which must emit FIX-1's out-of-place stream and never a handle in an immediate slot) — and then your OWN new spellings (≥ 10) of
   the mixed shape (incl. a preheader in-place op on either register, and the onward variants), including the interplays the lens was told to probe (preheader-gate multiplicity with both
   registers; the record question; the two collapse passes with an onward region in the mixed loop; Q-R1-1's
   controls still leaking byte-identical to PRE-FIX). ⚠ THREE fix rounds on one finding, the second of which INTRODUCED a once-only-stage miscompile of its own: treat every stage this epic added or moved (`commitOutOfLoopInPlaceOps` and its lowering-time tripwire, the per-loop `ClaimedRailRoots`, the count-keyed round-2 re-offer, the `Collapsed`-branch union) as a NEW once-only-stage candidate and ask notes §2's question of each with a program. Then SAMPLE the four confirmed classes of the two rounds
   with new spellings (the spine adjoint on the shared flag; the once-only-stage class; the retired-family third
   path; the per-bit discharge) — 3–5 each — and confirm every previous-clearance CLEAR item you re-run is
   byte-identical between PRE-FIX and the subject (the fix must change NOTHING outside the mixed population:
   measure it with a sweep of every accept fixture's output and every golden — `diff` PRE-FIX vs subject).
2. **Does anything free a rail that is not provably |0⟩, or leave a rail dirty where the oracle discharged it?**
   STRICT stage 2b on every reproducer; the rolled/unrolled twin gates (now incl. `e2e-phase-perbit-loop-mixed-
   twin-identical`); the golden audit (`tools/golden_multiset_audit.py --epic 3qlq --rev 52d7764 <changed goldens>`)
   over the regenerated goldens — the two new goldens are NEW-FILE, nothing else moved; the void loop twin matrix
   green with the NEW axis and no new quarantine cell (if one was added, it needs a class and a bd issue and is
   NOT a blessing); `e2e-loop-twin-quarantine-selftest` green.
3. **Is every accept pinned and every decline mirrored, and does the record tell the truth?** The injection
   matrix (`$SP0/progress/clearance_work/inj.py`, re-pointed) over the previous 68 accepts PLUS every new accept
   fixture of this round — every injection caught, with the clean + known-bad controls; the B3 fixture pins the
   B3 string and its control accepts; the notes' §3 counts re-measured; PRD §0 E2 true of the binary; the
   CLAUDE.md sentence true; the previous clearance's §4 items each either pinned, filed (bd), or still open — say
   which; D1–D7 honoured and §12 Q1–Q4 still consistent with what shipped; the ctest entry count (`ctest -N`)
   vs the count CLAUDE.md will claim (the orchestrator updates it from your number).

## Known before you start (do not re-grade these as this tree's; do re-measure them)
* **bd `test_C_libtooling-eqpx` (P1, PRE-EXISTING on the pre-3qlq oracle 52d7764, unchanged by this tree):** an
  in-loop in-place XOR whose immediate is DERIVED from a 6.5/4.5 onward `%out` emits `cqrt_xorc_i32(h, <handle id>)`
  (lens review_c1c F-C1C-B; reproducers `$SP/progress/review_c1c_work/p/c1c_m_xor_*.c` + the 2nd TU). Confirm it is
  byte-identical ORACLE == PRE-FIX == SUBJECT (so it is not a regression), and say so in §1; it is an owner item, not
  a BLOCK of this landing, unless you find a spelling this tree makes WORSE or newly reachable.
* The subject's tip moved after lens 3 by a docs+comments commit (record-truth fixes F-C1C-B/E/F + counts) and a
  rebuild; verify the binary is current and that `lit` is green on it before you cite either.
* Owner questions carried forward from the three rounds: OQ-C1-1..9 (notes §3.9 / §3.11), OQ-1 → bd 67n5,
  b2u/b6u → bd 3qlq.9, OQ-29 → 3qlq.10, OQ-21 → 3qlq.11, Q-R2-1/3 → 3qlq.12.

## Verdict (last line of your report, exactly one of)
`CLEAR` · `CLEAR-WITH-OWNER-QUESTIONS` (list them) · `BLOCK` (the finding, the reproducer, the two traces).
A BLOCK needs one reproducer with a wrong unitary or a dirty free; an unpinned accept or a false sentence is a
CLEAR-WITH-OWNER-QUESTIONS item unless it hides a wrong unitary. Write `$SP/progress/clearance2.md`; return it.
