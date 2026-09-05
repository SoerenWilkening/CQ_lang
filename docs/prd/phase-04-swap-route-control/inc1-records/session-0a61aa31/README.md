# Session 0a61aa31 (2026-09-05) — the review record of 3qlq Inc 0 + Inc 1 (+ Inc 2 round 1)

Copied verbatim from the session scratchpad at hand-off so the record survives the scratchpad. Reading order:
`OWNER_QUESTIONS.md` (OQ-1..OQ-29 with the orchestrator's dispositions) → `clearance.md` (VERDICT: **BLOCK** on
C-1, the mixed-loop per-bit leak; reproducer in `clearance_c1/`) → the round reports (`review_r1_L1..L8`,
`review_r2_R1/R2`, `review_flips`, `review_inc2_V1/V2`) → the hand-backs (`impl_*`, `fix_*`, `prep_*`,
`docs_final`) → `briefs/` (every agent brief incl. `BRIEF_review_inc2_r2.md`, unused). Nothing here is on main:
the branch is `3qlq-inc1` (this commit) and Inc 2 is `3qlq-inc2`.

**SESSION 2 (adc5590a, 2026-09-06) — the C-1 FIX ROUND — has its own record directory,
`inc1-records/session-adc5590a/`** (`fix_c1.md`, `review_c1.md`, `clearance2.md`, `briefs/`), **copied at
landing** the same way this one was. Read it AFTER `clearance.md`: it carries the fix for the BLOCK
(`LoopLowering`'s `Collapsed` branch admitting loop-invariant root mints beside the carried roots), its
red-green and mutation validation, the C-1 population table over three binaries, and the re-clearance
verdict. This directory is the record of the BLOCK; that one is the record of its disposition. Until the
re-clearance lands, neither branch is on main.
