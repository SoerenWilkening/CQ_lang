# BRIEF_review_c1 — ONE narrow Rule-13 lens on the C-1 FIX (3qlq Inc 1, the clearance BLOCK), READ-ONLY
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_fix_c1.md` (what the fix agent was asked to do), then
`$SP/progress/fix_c1.md` IN FULL (what it did and measured), then from the repo record dir
`docs/prd/phase-04-swap-route-control/inc1-records/session-0a61aa31/`: `clearance.md` §2.2–§2.3 (C-1 and its
population), `fix_r1.md` (F-L5-1), `fix_r2.md` (F-R1-1), `review_r2_R1.md` (the lens that found F-R1-1 — its
method is yours), and `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §2 ⭐ table + the new §3 the fix agent wrote.
Agent name: `review_c1`. Model: opus. READ-ONLY on every checkout (you may write under `$SP/progress/review_c1_work/`).

## Binaries (name every path you use; three of them)
- SUBJECT (the fix): `$SP/wt/fix-c1` at 3ec40c9 — build current (verify: `find ir-pass/src ir-pass/include
  -newer build/ir-pass/cq-opt` → empty).
- PRE-FIX: the main checkout `/Users/sorenwilkening/Desktop/CQ_lang` at 542d588 (build current, never rebuilt).
- ORACLE: `$SP0/wt/pre-3qlq` (52d7764, the pre-3qlq register surface — old-surface twins only).
Harness: copy `$SP/progress/fix_c1_work/run.sh` (4 cases: subj = pre-fix, fix, r1s, orac) — control it with a
clean run and a known-bad run before you trust one number from it.

## What the fix did (from the brief; verify against the diff `git -C $SP/wt/fix-c1 diff 542d588 -- ir-pass/src`)
`collapseFlattenedLoopRails`, on a `Collapsed` carried rail, now ALSO admits the loop-INVARIANT ROOT MINTS (and
clause (ii-b) control-owned merge out-rails) beside the carried roots before `markIfRailLocal`, on the (I1)
argument (a root mint lowers to `cqrt_alloc`+`cqrt_ry`, fails `isInteriorTerminalHandle` (I1), so it can never be
the preheader forward gate whose `At` lands in the K-times body). Candidates whose peeled base is already a
carried root are SKIPPED (the collapse's proof covers them). A failed extension falls back to the carried roots
only (today's behaviour). Q-R1-1's hoisted TEMPLATE rail stays refused.

## Your questions — each answered by a MEASUREMENT (a program through all applicable binaries, rolled vs unrolled) or an analytic argument you performed
1. **The 8h7d.5 question, adversarially.** The closure widened is "the Roots `markIfRailLocal` calls THE
   REGISTER". Enumerate every predicate computed over Roots / `IterationLocalBlocks` / `InPlaceRailOps` in
   `LoopLowering.cpp`, `Uncomputation.cpp`, `FreePoint.cpp`, `ChainWalk.cpp` and MEASURE each against the fix
   agent's table (constraint 6 of its brief). The one that matters most: the MULTIPLICITY hazard
   `markIfRailLocal`'s own comment names — a recovered forward gate in the PREHEADER (executes once) paired with
   an `At` in the marked body (executes K times). With a carried rail AND an invariant root both admitted, can a
   gate on the CARRIED rail's pre-loop chain (e.g. `r = cq_theta(u,.3); r = r * 5;` or `r ^= 3` BEFORE the loop,
   then `r = cq_theta(r,.1)` in the body) or on the invariant register's pre-loop chain (`q = cq_theta(u,.5);
   q = q + 7;` before the loop, invariant inside) become a preheader gate whose adjoint is placed in the body?
   Construct it, both orders, both registers, and read the emitted stream: any `_unc`/`_inv` in the body whose
   forward is outside the loop is a CONFIRMED wrong unitary (K adjoints of one gate). Then the RECORD question
   (F-3's mirror): does admitting `%q` create a rail RECORD read that `staleRailRecordRead` (collapse step 2b)
   never examined — the body's reads of `%q` against the post-loop diffusion `q = cq_theta(q,.9)`, and a
   post-loop read of a pre-loop alias `int mark = q;` — does the fence still decline `rail record read past an
   in-place gate` where it must?
2. **The two collapse passes and Q-R2-1.** The mixed loop with an ONWARD region opened in the same body at
   round 2 (a 6.5 `%out` per-bit kickback beside the round-1 per-bit kickback and the carried `r`): the round-1
   marking stands and the round-2 re-offer sees erased phis. Measure rolled vs unrolled; then the reverse
   nesting (onward region first in source order); then an onward register as the CARRIED one (`y` gated by an
   in-place `add` in the body — is that even a shape? say so) and as the INVARIANT one beside a carried root
   mint. Any leak that the unrolled twin discharges is a finding of the once-only-stage class.
3. **The population, re-run by you, not read from the hand-back**: every `d*`/`e5`/`d1w` pair in
   `$SP0/progress/clearance_work/p/` plus the fix agent's new spellings, on PRE-FIX and FIX, `and_hl`/`and_unc`
   (and `lshr`) counts, STRICT 2b, rolled == unrolled byte identity. Then NEW spellings of your own (≥ 12): the
   invariant register at a different width (`long`/`short`/`_Bool` root), the carried register as a `double`
   Ry chain, a kickback whose condition mixes the invariant and carried registers in one P3 tree with the
   carried leaf NEGATED, two invariant roots + two carried, the invariant register read by a 7.6 tape write in
   the body, the invariant register as a QRAM index in the body (must decline — L3), a `break` in the mixed
   loop (must decline), a nested mixed loop (must decline), an irreducible/multi-latch mixed loop (must
   decline), the carried register also a kickback condition with a DERIVED chain, a mixed loop inside a
   specialised callee, and the mixed loop with the carried register's gate placed BEFORE the kickback. Also
   the Q-R1-1 controls (`d2`, `d3`, `b7`, and the mixed hoisted-template spelling): still leaking, and
   BYTE-IDENTICAL to PRE-FIX.
4. **Red-green and fixture truth, briefly** (the clearance does the injection matrix; you check the claims):
   each new fixture RED on PRE-FIX / GREEN on FIX as claimed (run them yourself); the mutation-validation cycles
   reproduce (re-apply the two disablings on a scratch copy of the worktree ONLY IF you can do it without
   touching `$SP/wt/fix-c1` — otherwise read the recorded diffs and say you did not re-run them); the B3 fixture
   really carries `cq loop lowering: early break preserves a phase answer` on both binaries; the matrix axis's
   274 pre-existing generated sources are byte-unchanged (re-derive with the HEAD script and the fixed script,
   diff); every number in fix_c1.md's tables reproduces.
Grade each finding: `CONFIRMED-MISCOMPILE` (a wrong unitary or a dirty free at `opt` exit 0), `LEAK`
(rolled≠unrolled with the unrolled discharging — the C-1 class), `OVER-DECLINE`, `DOC`, or `CLEAR`. Write
`$SP/progress/review_c1.md` with numbered findings F-C1-k, reproducers under `$SP/progress/review_c1_work/`,
a "what I ran" section, and a verdict line: `CLEAR` / `CLEAR-WITH-ITEMS` / `FINDINGS` (fix round needed).
Return the report as your final message.
