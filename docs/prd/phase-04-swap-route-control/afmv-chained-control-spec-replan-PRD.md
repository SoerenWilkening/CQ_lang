# afmv — Chained onward control → spec re-plan (stale-mask miscompile fix)

**Status:** implemented 2026-07-05 (branch `dugh-repropagate-control-merge`, bundled
with 9paa). **Severity: P0 — a verify-clean silent miscompile, reachable from clang
-O1.** Discovered by the 9paa Rule-13 adversarial workflow (dedup-pending-diagnosed
dimension); independently reproduced + attributed by git-stash A/B. Owner-directed
fix (2026-07-05, "Full proper re-plan fix now"). Core-lowering change — cleared via a
second adversarial Rule-13 pass before commit.

## 1. Problem (the miscompile)

`yn71` (onward tainted CONTROL) replaced dugh's blanket `declineReClassifiedControl`
with `detectAndLowerOnwardControl`, which lowers a **chained** downstream
tainted-condition region and builds a NEW `%out2` control rail (a genuine i32 quantum
handle). But a **round-1 Phase-6 `Pending` spec candidate** whose argument becomes a
`%out2` rail keeps its **frozen mask**, and the step-262 driver clones it reading the
superposed rail as an `_hl` **classical literal**.

Reachable from clang -O1 (2-file):

```c
// caller (CQ TU)             lib: int ext_f(int a){return a+100;}  int gg(int a,int b){return a*b;}
q = cq_theta(q, .5);
int y=5;  if (q>5)  y = ext_f(7);   // region 1: 6.5 classical-call arm -> %out1 (round-1 rail)
int w=6;  if (y>50) w = ext_f(7);   // region 2: cond reads %out1 -> yn71 -> %out2 (round-2 rail)
int z = gg(w, q);                   // ROUND-1 Pending gg(w=%out2, q): mask frozen 0b10
m1 = cq_measure(z);  m2 = cq_measure(y);   // measure(y) keeps region-1 merge live -> both rails
```

Pre-afmv trace (WRONG): `cq_template_mul_i32_hl(h0, 7) -> h11` — the clone
`@__cq_q_gg_10` multiplies the theta register `h0`(q) by **7**, the runtime handle-ID
of the `%out2` rail `h7`, instead of the QQ multiply `q × out2`. `opt` exits 0,
verify-clean, `measure` returns 0 — a plausible trace, a wrong unitary.

## 2. Root cause

`repropagateControlMerges` (TaintPropagation.cpp) computed the round-2 `reseed` set
**before** `detectAndLowerOnwardControl` (yn71) ran, and `replanReseedSpecialization`
(0vvq Inc 2) re-plans only a `Pending` candidate reading that frozen set. The yn71
`%out2` rail is created AFTER, so it is not in the frozen `reseed` set, so a `Pending`
candidate reading `%out2` is never re-planned. `declineTaintEscapes` then **carves**
it (`shouldSpecialize` = true, it is `Pending`) rather than declining, so the driver
clones the stale mask. yn71's clearance assumed "spec-off-a-round-2-rail declines
cleanly via `kMsgUnknownCallee`" — TRUE for a NEW candidate (not in `Pending`), FALSE
for a round-1 `Pending` candidate (carved, not declined). This defect predates 9paa
(git-stash A/B: identical on the pre-9paa plugin); it was introduced by yn71.

## 3. Fix — reseed AFTER the control fixpoint (a combined spec/control fixpoint)

Reorder `repropagateControlMerges` so the yn71 control fixpoint runs BEFORE the reseed
computation and the spec re-plan/re-detect:

```
propagateWorklist(rails)
lowerByRefMath fixpoint (0vvq Inc 1)
detectAndLowerOnwardControl(...)                     // yn71 — MOVED UP (builds %out2 rails)
reseed = UntaintedMergeRails ∪ (Tainted − snapshot) // now includes %out2 rails + downstream
replanReseedSpecialization(taint, wd, plan6, reseed) // re-widens gg 0b10 -> 0b11
detectSpecializations(M, taint, wd, plan6, &reseed)  // 9paa — new candidates off %out/%out2
declineTaintEscapes(M, taint, plan6)
declineStaleRecordOps(M, taint)
```

The yn71 emitters (6.5 classical-call arm, 4.5 switch data-mux) record every `%out`
they build in `taint.UntaintedMergeRails`, so after the fixpoint `reseed` spans the
`%out2` rails and their taint. `replanReseedSpecialization` then recomputes `gg`'s
mask against the final taint: `0b10 → 0b11`, re-classifies (Accept — `%out2` is an i32
handle), and the driver clones `@__cq_q_gg_11` with a **bare-QQ** `cq_template_mul_i32`
over two quantum handles. A newly-tainted **non-i32** arg (`gg16((i16)%out2, q)`)
loud-declines step (A) `kMsgFpAbi` and is dropped from `Pending` (never cloned stale).

Fixed trace: `cq_template_mul_i32(h0, h7) -> h11` (q × %out2, both HANDLES) reversed by
`cq_template_mul_i32_unc(h11, h0, h7)`.

## 4. Soundness / why safe

* **Monotone taint.** Taint only grows across rounds; a `Pending` candidate whose mask
  is unchanged is skipped (`NewMask == Cand.Mask`). Only a candidate reading a genuine
  round-2 rail is touched.
* **`%out2` is a valid i32 quantum handle** (a `cqrt_alloc_i32` the yn71 emitter
  builds + controlled-copies), so reading it bare-QQ is the correct unitary.
* **Ordering safety** (the 9paa broken-module hazard stays closed): the spec re-plan/
  re-detect still run AFTER the control fixpoint, so no un-lowered pre-lowering merge
  phi can enter `Pending` (§4 of the 9paa PRD).
* **No new control from the spec side.** The re-plan/re-detect only update
  `plan6.Pending` (no IR emitted; clones are built at step 262), so no cascade loop is
  needed — the yn71 fixpoint fully settles control/taint, then one spec pass suffices.
* **The 0vvq/dugh/yn71 fixtures are unchanged**: for a module with no downstream
  control, `detectAndLowerOnwardControl` is a no-op, so moving it earlier changes
  nothing; the re-plan runs against the same `reseed`.

## 5. Capability unlocked (the 9paa cascade follow-on, now closed)

With `%out2` in the reseed set, 9paa's `detectSpecializations` also DETECTS a
**wholly-new** candidate reading a `%out2` control rail (previously a deferred safe
over-decline). So `h(%out2)` (all-classical at round 1) clones `@__cq_q_h_1` bare-QQ.
This is the "combined spec/control fixpoint" the 9paa follow-on anticipated.

## 6. Fixtures (Rule 12) + e2e

* `control_classical_call_arm_accept_onward_ctl_spec_replan.ll` — the core fix: chained
  control, round-1 `Pending` `gg` re-widened `0b10 → 0b11` bare-QQ (`CHECK-NOT
  @__cq_q_gg_10`, `CHECK-NOT cq_template_mul_i32_hl`).
* `control_classical_call_arm_accept_onward_ctl_spec_newcand.ll` — the cascade: a NEW
  candidate off a `%out2` rail, detected + cloned bare-QQ.
* `control_classical_call_arm_reject_onward_ctl_spec_fparg.ll` — a non-i32 (`(i16)%out2`)
  re-plan arg → `kMsgFpAbi`, no `unknown callee`.
* e2e `e2e-slice-control-spec-chained-ctl` (`run_slice_multi.sh`): the clang -O1
  miscompile repro, now LINK-proving the `cq_template_mul_i32(h0, h7)` bare-QQ contract.

## 7. Rule-13

A second adversarial finder+verifier workflow re-run on the combined 9paa+afmv tree
(the same 8 dimensions), specifically re-probing the chained-control × spec-candidate
interaction, deeper nests, the switch-data-mux `%out2` variant, and guard-malloc
lifetime. Must clear with 0 confirmed silent-miscompile/crash/broken-module before
commit.
