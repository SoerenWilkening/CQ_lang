# progress — review_r2_R2 (Rule-13 ROUND 2, lens R2: FIXTURE / DOC TRUTH of the whole branch)
SUBJECT = /Users/sorenwilkening/Desktop/CQ_lang @ c4bd888 (build 16:53, READ-ONLY, never edited/rebuilt)
ORACLE  = $SP/wt/pre-3qlq @ 52d7764
R1SUBJ  = $SP/wt/r1-subject @ fa96336
All my files under $SP/progress/review_r2_R2/.

## 2026-09-05 step 0 — setup
- Read BRIEF_common, BRIEF_review_r2, BRIEF_review_r1, fix_r1.md, impl_inc1a.md, impl_inc1b.md,
  review_r1_L8.md, review_r1_L6.md.
- Verified subject HEAD = c4bd888, working tree CLEAN, cq-opt+libCQPass mtime 16:53 (post-merge).

## step 1 — corpus disposition (MEASURED)
- `cd build && lit -q ir-pass/test` -> **1661 discovered, 396 FAILED** (log review_r2_R2/lit_full.log).
- `git diff --name-status dfb8e83..c4bd888 -- ir-pass/test` -> **79 A + 1 M = 80 files**.
- All **80 branch fixtures GREEN** (comm of red.txt x branchfx.txt = empty).
- `grep -lE '@cq_phi_[a-z0-9]+' ir-pass/test/*.ll` -> **493**; `red \ migset` = **EMPTY**.
  => fix_r1's "396 red, all inside the 493 retired-family set" REPRODUCES EXACTLY.

## step 2 — full-corpus sweep on the SUBJECT (MEASURED, review_r2_R2/sweep.tsv, 1661 rows)
- rc=0 on **633**, rc=1 on **1028**.
- **Emitted `cqrt_rz` set: `cqrt_rz_i1` ONLY.** 35 fixtures emit it, 598 emit no `cqrt_rz`,
  **0** emit any other width. PRD §5's "cqrt_rz_{i8..f80} not emitted" REPRODUCES.
- `cqrt_cswap` is emitted by **12** fixtures: 4 abort-park + 8 VALUE-arm/value-switch routes.
  `grep 'emitRoute('` -> callers are `AbortParkEmit.cpp:396`, `SwapRouteEmit.cpp:380/414/441/455`
  (value arm) and `SwitchValueEmit.cpp:204/228/257/266` (4.5 value switch).
  => the BRIEF's "cqrt_cswap is minted by AbortParkEmit only" is the POST-Inc-2 end state
  (PRD line 133/234), NOT true at Inc 1 HEAD. Recorded as F-R2-x (brief premise, not a defect).

## step 3 — injection matrix (review_r2_R2/matrix.tsv), 37 accepts x 8 injections + 2 controls
Controls: clean PASS 37/37; known-bad FAIL 33/33 applicable; two deliberately broken fixture
copies (retargeted CHECK / inverted NOROUTE-NOT) both FAIL. Anti-lie audit: every injection is
a ONE-LINE edit and touches NO `declare`; every post-line-0 RUN is a pure FileCheck (no reparse).
MISSES: g_drop_mark 22, e_drop_free 2, c_rz_after_free 2, a_cswap 1, d_surviving_phi 1.

## step 4 — measurements (all MEASURED on the subject unless stated)
- Decline strings: 43/43 declines exit 1 with EXACTLY ONE `error:`; every positive CHECK is a
  literal substring of the emitted stderr; every message text is present in `ir-pass/src`
  except the two that are BUILT by concatenation (retired-register-form, QRAM table read).
- Handle names: 0 literal `%name` in any positive directive of the 37 accepts is absent from
  that fixture's own pass output (`handlecheck.txt`, 464 positive directives scanned).
- Stage-2b STRICT on all 37 accept outputs: 37/37 rc=0, 0 violations, 0 unproven.
- 3-binary disposition of all 80 (threebin.tsv): every part-B accept RC 1->0 vs BOTH the
  oracle and the fa96336 r1-subject; F-L3-4/F-L4-1/F-L3-1(B) all confirmed fixed (r1 rc=0 ->
  subj rc=1); `..._reject_compound_cond` and `..._reject_onward_mixed_arm` now SAME-MSG as
  the oracle, which is what their headers claim.
- `!cq.branchphase`: 6 emission call sites; 13 fixtures assert the tag. Per-gate drop map
  (markmap.tsv) shows EVERY site is pinned by >=1 fixture, but 22 of 35 gate-bearing accepts
  are blind to a dropped mark, and the AngleSelectEmit stem is pinned by exactly ONE file.
- `free_pairing_check.py` catches dropstrip/extrafree/unpairedx on the nest+switch shapes
  (rc=1) and does NOT catch `cqrt_rz_f80` (rc=0, cqrt_rz is transparent by design).
- 63 of the 66 `tests/e2e/*.c` that call `cq_phi` FAIL stage 1 on this branch's header, so
  stage 2b runs on NO kickback program at c4bd888.

## step 5 — remaining measurements
- Blast radius: `comm -13 red_r1.txt red.txt` = **34 new red, 0 newly green**, all in the 493.
- Inherited-corpus diff (1581 files, subject vs fa96336): **396 changed = 15 RC 0->1 +
  381 message pre-emptions + 0 STDOUT changes**; every one the F-L6-1 reserved-name decline.
- F-L6-2 census re-measured at fa96336 by re-running lit there: 1602/362/491/**129 = 103+26**,
  35 live-call of which 4 accept -> the notes REPRODUCE EXACTLY.
- Notes "19 call sites in 6 files" -> MEASURED **21 in 7**, identically at c4bd888/fa96336/71d4cce.
- Notes "Recorded at all THREE emission sites" -> MEASURED **SIX** markBranchPhaseGate sites.
- Two fixture headers still claim "broken module at opt exit 0" (F-L3-5 corrected only the
  two SOURCE comments).
- Three fixture headers + the notes cite e2e artifacts ABSENT or non-compiling here.
- `control_phase_switch_reject_default_body.ll` is not a discriminator for its named cause
  (disc/d1.ll still declines; only re-pointing the default EDGE accepts, disc/d1b.ll).
- Frontend NOFAM fix validated by 3 injections + clean control.

## HAND-BACK
Report written to $SP/progress/review_r2_R2.md (494 lines: harness + 4 controls, corpus
table, per-accept injection matrix (37x10), per-decline table (43), 11 numbered findings
F-R2-1..11, a 13-item CLEAR list, a "did not verify" list and a verdict line).
VERDICT: NOT CLEAR — 0 miscompiles, 0 over-accepts, 5 substantive DOC-OR-FIXTURE-TRUTH
findings (F-R2-1 systemic), 6 informational. All fixes are fixture/prose edits.
