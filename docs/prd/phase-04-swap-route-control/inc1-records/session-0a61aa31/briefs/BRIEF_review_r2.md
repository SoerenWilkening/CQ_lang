# BRIEF_review_r2 — Rule-13 ROUND 2 on Inc 1 (part A + round-1 fixes + part B), two narrower lenses
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_review_r1.md` (the round-1 lens list and grading),
then `$SP/progress/fix_r1.md` (what the fix agent changed and why), `$SP/progress/impl_inc1b.md`
(P3/P4/P5), and the round-1 reports `$SP/progress/review_r1_L{1,2,3,5,6,7,8}.md` (skim the
findings sections; each lens's CLEAR list tells you what NOT to redo). Agent name:
`review_r2_R<n>`. Model: opus. READ-ONLY. SUBJECT = main checkout at c4bd888 (build current);
ORACLE = `$SP/wt/pre-3qlq`; ROUND-1 SUBJECT (for "did the fix change anything else") =
`$SP/wt/r1-subject` at fa96336 (build present) — three binaries.

## R1 — the FIXES, adversarially (the 8h7d.5 lesson: "when you widen a set, ask what OTHER set was
## computed over the same closure"; F2 took four generations)
For each round-1 fix: re-run its reproducers (they are under `$SP/progress/review_r1_L*/`), then
attack the FIX. Specifically:
- **BranchPhaseGates / phased-register opacity (F-L7-1):** the spine is now opaque to recorded
  kickback gates. Enumerate every consumer of the same closure the fix agent listed and MEASURE
  each (railOf, isTerminalHandle, isInteriorTerminalHandle I1/I3, DagTraversal step-1/step-3,
  Uncomputation moved-anchor + clause (d), preservesBorrowedParent (1b), lowerBreakReversePlay,
  free_pairing_check classify). Probe: shared flag with a `zext` data use that is itself measured /
  returned / tape-written / passed to a clone / used in a second region's condition; a shared flag
  under the merge-tail phi; a shared flag in a rolled loop; TWO kickbacks on one shared flag; a
  shared flag whose data use is a `select`. The correct disposition on every one is either the
  oracle's ziov stream (flag left allocated, phase intact) or a loud decline — never an adjoint,
  never a dirty free. Also the phased-REGISTER record (F-L5-6): does a `break`/`ret`/abort whose
  escaping answer carries a kickback phase now decline? Construct it past the earlier fences.
- **deleteGlobalPhases reorder (F-L3-1):** onward-control phases now lower. Probe the round-2
  interactions the fix agent named (declineTaintEscapes' PhaseCalls carve; detectSpecializations at
  round 2 with a tainted-angle cq_phi; a phase under a SECOND onward region; onward + ShareCondFlag;
  onward + angle select; onward + in-loop). And the reverse: is a GENUINELY classical-control phase
  still deleted (not declined) after the move?
- **Retired-family decline (F-L6-1):** a declared `@cq_phi_<sfx>` now declines. Does anything in
  the tree still CLAIM the family by prefix before that decline fires (ArmClassify isPhiCall,
  RegionTreeDetect, SwitchArmProve…)? Order of diagnostics under `cq-opt`'s first-error exit.
- **In-loop derived-condition discharge / per-bit (F-L5-1):** whichever disposition shipped —
  rolled == unrolled byte-identity on the per-bit K=2/4/32 pairs, on derived conditions with and
  without a body gate, on two derived-condition regions per trip, on a derived condition whose chain
  is shared with a data use; if it was a DECLINE, confirm the flat/unrolled forms still accept and
  the decline string is pinned.
- **Part B (P3/P4/P5):** compound flags — LIFO order of node undo vs leaf strips; the OR/XOR node
  ancilla freed after its undo; a leaf shared between two trees; a classical leaf; `select i1 %a,
  i1 %b, false` where %b is itself a compound; the nest vs `&&` byte identity; the switch per-case
  flags with a default that is not empty (must decline), with a case whose arm has N gates, with a
  case value equal to the compare constant of an enclosing region; the switch.table fold from C.

## R2 — fixture / doc truth of the WHOLE branch (part A + fixes + part B)
Every fixture added or rewritten since dfb8e83: re-derive CHECKs from the subject, handle names
exist, counts in their own prefixes, NOROUTE pure-negative, decline strings character-for-character
in the source, injection matrix (the L8 six + a negated-angle adjoint) over every accept — including
part B's — with controls. Every claim in `RETIRE_SWAP_ROUTE_INC1_NOTES.md` and in the fixture headers
checked against a measurement (the notes must not repeat the "opt exit 0 on verifier failure" error
or the 155/129 count slip). Confirm the emitted Rz set is `cqrt_rz_i1` ONLY across all fixtures
(the L6/L8 sweep) and `cqrt_cswap` is minted by AbortParkEmit only (grep + sweep). Report per file.

Both lenses: write `$SP/progress/review_r2_R<n>.md` with numbered findings and a verdict line;
return it as the final message.
