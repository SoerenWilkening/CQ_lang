# BRIEF_review_eqpx_r2 — NARROW LENS, round 2: fixture/record integrity of the docs+fixtures round, and the two gates round 1 did not run

Agent name: `review_eqpx_r2`. Progress file: `$SP/progress/review_eqpx_r2.md`. Work dir: `$SP/progress/review_eqpx_r2_work/`.
Read `$SP/briefs/BRIEF_common.md` FIRST, then `BRIEF_fix_eqpx.md`, `BRIEF_review_eqpx_r1.md`, `BRIEF_fix_eqpx_b.md`, then
the progress files `$SP/progress/fix_eqpx.md`, `review_eqpx_r1.md`, `fix_eqpx_b.md` — WHOLE.

SUBJECT: `$SP/wt/eqpx`, branch `eqpx-fix` at **beb34e0** (round-1 code tip 1333278 + the docs/fixtures round). READ-ONLY:
verify currency and a clean `git status --porcelain`; build mutants only under `$W/`. Binaries: `main` =
`$SP/bin/main-16b15b3/`, `orac` = `$SP0/wt/pre-3qlq`, `fix` = the subject, `fix-r1` = `$SP/bin/eqpx-1333278/` (the
round-1 code binary — the subject's `cq-opt` must be `cmp`-BYTE-IDENTICAL to it; MEASURE that first).

## Your question is NARROW: did the docs+fixtures round close F-E1-1/2/3 and (A)/(B) HONESTLY, and do the two gates
## round 1 did NOT run pass on this tree? You are not a third adversarial round on the lowering (round 1 was CLEAR on it).

1. **Code did not move**: `git diff 1333278..beb34e0 -- ir-pass/src ir-pass/include | grep '^[+-]' | grep -v '^[+-]\s*//' |
   grep -v '^+++\|^---'` EMPTY, and the `cmp` above. If either fails: BLOCK.
2. **F-E1-3 closed**: re-run the round-1 lens's `inject2.sh` (in `$SP/progress/review_eqpx_r1_work/`) over the 8 accept
   fixtures on the subject → 0 MISSED, clean control green ×8. Then ADD two injections of your own the round-1 matrix did
   not have: (d) an extra `cqrt_xorc_i32(%h, 7)` with a CONSTANT immediate (a second in-place gate — the Rule-8 fan-out
   shape), (e) a `cqrt_addc_i32` where the fixture expects `xorc` (stem swap). Report caught/missed per fixture. A miss
   is a FIXTURE item (not a block) unless it is the rail-immediate form.
3. **F-E1-2 closed honestly**: each of the 8 decline fixtures' header says the `RUN: not` inversion pins the property and
   the `CHECK-NOT`s cannot fire (or the CHECK-NOTs are gone). Mutant M-B (silent fallback) → the 8 go RED. Re-measure.
4. **F-E1-1 closed**: `grep -n 'markInPlaceRailOp(' ir-pass/src/LoopLowering.cpp` → 4 caller lines; every comment in
   `OpcodeLowering.cpp`, `LoopLowering.cpp`, `TaintPropagation.h` that enumerates the writers agrees with those lines
   (or cites names without numbers). `grep -rn 'InPlaceRailOps.insert' ir-pass/src` → 1 (the helper).
5. **(A) in-source**: `ArithLowering.cpp`'s consume comment carries the three-fact argument and states the M2+M3 / M-E
   status honestly ("agrees with `TL` on every corpus program; live when wrong").
6. **Record truth**: notes §3.16's round-1 subsection, PRD E13, `CLAUDE.md`, `ROADMAP.md`, the new
   `inc1-records/session-7bbdb89e/eqpx_reproducers_r1/` dir + README — every number reproduces by command (re-run the
   census on ≥10 of the 15 members and ≥5 of the 20 controls yourself, on `main` and `fix`); no sentence claims the
   class is closed beyond the four writers; §3.12's ADD row is marked falsified, not deleted; the `y07` sentence says
   wrong-IMMEDIATE face plain-C / wrong-REGISTER face hand-IR; the `x09`/`x10` sentence says rc 134 broken module on
   `main`, decline on the fix.
7. **THE TWO GATES ROUND 1 DID NOT RUN — the ORCHESTRATOR is running the FULL `ctest -j6` on the subject build
   right now** (log: `$SP/progress/orch_full_ctest_eqpx.log`; it ends with a `tests passed` summary line and `EXIT=<rc>`).
   Do NOT start a second `ctest` in the subject build tree while that log has no `EXIT=` line (two concurrent runs in
   one tree contend and produce FALSE reds). When it has finished, READ it: report the exact summary line, the
   `e2e-loop-twin-matrix`, `frontend-lit` and `runtime` rows, and any failure. Then `git status --porcelain tests/ tools/`
   EMPTY (0 golden churn, 0 matrix churn). Say "READ, not run" in your table. Your own lit/harness runs are fine meanwhile.
8. **One last sweep in the ACCEPT direction on the final tree**: `strictimm.py` over every accept of the 1707+ fixtures
   AND over the 43+43+20 reproducers on the subject → 0 rail producers. Report the count.

## Verdict
`CLEAR` / `CLEAR-WITH-ITEMS` / `BLOCK`. Findings `F-E2-<n>` with reproducer, binaries, measured result, grade. Anything
contradicting a PRD §2 decision → `## OWNER QUESTION`. End with "WHAT I RAN" + "NOT run".
