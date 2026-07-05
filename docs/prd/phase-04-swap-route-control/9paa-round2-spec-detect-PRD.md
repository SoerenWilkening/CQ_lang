# 9paa — Round-2 spec DETECTION: lift a wholly-new Phase-6 candidate `g(%out)`

**Status:** implemented 2026-07-05 (branch `dugh-repropagate-control-merge`).
Closes the **spec side** of the dugh Phase-4×6 arc. Owner-directed accept-more
follow-on from `dugh`/`0vvq`/`yn71` (2026-07-04): *"lower/compile everything not
ruled out by physics."* Core-lowering change (clone × merge composition) — cleared
via a multi-agent adversarial workflow before commit (Rule 13).

## 1. Problem

`dugh` re-propagates the untainted control-merge `%out` (the 6.5 classical-call
arm / 4.5 switch data-mux out-rail) so onward-quantum flow lowers. `0vvq
Increment 2` (`replanReseedSpecialization`) **RE-PLANS** an *existing*
`plan6.Pending` spec candidate whose frozen per-arg mask GREW when `%out` became
round-2-tainted (e.g. `ipow(q, %out)` — arg0 the round-1 theta handle made it a
round-1 candidate, arg1 `%out` re-planned `0b01 → 0b11`).

`0vvq` deliberately did **not** re-DETECT a *wholly-new* candidate: a visible pure
body `g(%out)` whose args were **ALL classical at round 1** never read a tainted
operand at `detectSpecializations` (step 127, pre-emit) — the merge phi was
data-untainted then — so it never entered `plan6.Pending`. After the second
propagation taints `%out`, `g(%out)` reads a tainted value it does not own, and the
re-run `declineTaintEscapes` loud-declines it `kMsgUnknownCallee` (safe
over-decline, Prime Directive; pinned by the old
`control_classical_call_arm_reject_onward_spec_newcand.ll`).

This is **physics-valid** (`%out` is a genuine i32 quantum handle; `g` is a
provably-liftable pure body — the exact clone-on-taint shape Phase 6 already
lowers) and **reachable on -O1** (a separate-TU `g` that GVN cannot collapse). It
is a distinct capability from the re-plan: a **round-2 `detectSpecializations`**.

## 2. Physics (accept-valid)

`%out` is a superposition register (an i32 handle entangled with `q`). `g` is a
VISIBLE, PURELY-CLASSICAL, NON-RECURSIVE, STRAIGHT-LINE i32 value body. Lifting
`g(%out)` to `@__cq_q_g_<mask>` computes `g(%out)` reversibly (forward templates →
`cqrt_copy_i32` copy-out → LIFO reverse-play → free scratch → `ret out`), Bennett-
wrapped, reading `%out` as the **superposed value** it is — exactly as a round-1
`g(q)` clone reads the theta handle. No new physics vs round-1 specialization; the
ONLY novelty is *when* the candidate is detected.

## 3. Mechanism — RE-RUN `detectSpecializations` on the reseed set

`detectSpecializations` is the single authoritative detection walk (Rule 14). The
fix RE-RUNS it as the DETECTION twin of `replanReseedSpecialization`, feeding the
SAME `plan6`, so the step-262 driver clones the newly-detected candidate. Three
round-2-only filters (each a no-op at round 1, where the plan is built one Site at
a time and `reseed == nullptr`) added behind a `reseed`-pointer gate:

* **(a)** skip a site already proven-Accept (`shouldSpecialize` / `Pending`) — owned
  by the driver or already re-planned by `replanReseedSpecialization`; re-pushing
  clones/retargets the SAME Site twice.
* **(b)** skip a site already loud-declined (`plan6.Diagnosed`, by round-1 detection
  OR by `replanReseedSpecialization`) — it rendered its one specialization message;
  re-diagnosing double-fires it.
* **(c)** consider ONLY a site whose newly-tainted arg is a **reseed value** (the
  control-merge `%out` or a `%out` data-derivation, the fixed set computed pre-
  control-fixpoint). A round-1-tainted-arg site was already adjudicated in round 1
  (and is in Pending/Diagnosed, so (a)/(b) already skipped it). Restricting to the
  reseed set keeps a candidate reading a **yn71 control-produced rail** (`%out2`,
  NOT in `reseed`) a SAFE over-decline via the escape net (a tracked yn71 follow-on)
  — never a silently-accepted cascade.

Signature: `detectSpecializations(M, taint, wd, out, reseed = nullptr)`; round-1
call sites (`run` step 127, `runOnFunction` step 339) pass no `reseed` and are
byte-unchanged.

## 4. Ordering (inside `repropagateControlMerges`)

```
propagateWorklist(rails)                       // re-taint %out + downstream
lowerByRefMath fixpoint (0vvq Inc 1)
reseed = UntaintedMergeRails ∪ (Tainted − snapshot)   // FIXED, pre-control-fixpoint
replanReseedSpecialization(taint, wd, plan6, reseed)  // 0vvq Inc 2 — re-plan EXISTING
detectAndLowerOnwardControl(...)               // yn71 — control fixpoint
detectSpecializations(M, taint, wd, plan6, &reseed)   // 9paa — DETECT NEW  ◄── added
declineTaintEscapes(M, taint, plan6)           // carve consults Pending/Diagnosed
declineStaleRecordOps(M, taint)
```

* **After `replanReseedSpecialization`** — the re-plan populates Pending (updated
  masks) and Diagnosed (re-plan rejects) FIRST, so the (a)/(b) dedup is correct: a
  reseed-reading round-1 candidate is already resolved and 9paa skips it (the
  `i16arg`/`qqcmp` boundaries below).
* **After `detectAndLowerOnwardControl`** (the load-bearing choice) — the CFG is
  fully settled: every downstream tainted-condition region is already lowered to
  its `%out2` rail or already loud-declined (and `opt` will exit). The `reseed` set
  is FIXED pre-control-fixpoint, so a candidate reading a `%out2` control rail is
  NOT in `reseed` → not detected → SAFE `kMsgUnknownCallee` decline (yn71
  follow-on). Were the redetect placed BEFORE the control fixpoint, a candidate
  reading a downstream region's PRE-lowering merge phi (which IS in the reseed set)
  could enter `Pending`; if that downstream region then DECLINES, the step-262
  driver would clone the candidate over an un-lowered data phi read as a quantum
  handle → a `report_fatal_error` broken module (yn71's exact robustness concern).
  Running after the fixpoint eliminates that hazard. A plain candidate call
  `g(%out)` is not a control construct, so the control fixpoint never touches it and
  the `%out` merge rail (built in round-1 control lowering, step 184) is stable
  across the fixpoint — the primary case is detected identically.
* **Before `declineTaintEscapes`** — REQUIRED so the `shouldSpecialize` carve
  suppresses the new site's `kMsgUnknownCallee` and it lowers instead.

## 5. Decline boundary (Prime Directive)

* A NEW candidate whose **body fails `scanBody`** (in-body control, measurement,
  `cq_*`, fp/i128 ABI, recursion, non-i32 return, non-reversibilizable) →
  `detectSpecializations` calls `diagnoseReject` + `Diagnosed.insert` (source-
  located specialization message); the escape carve then suppresses the double
  `kMsgUnknownCallee` (filter (d) — the Diagnosed dedup). Fixture:
  `reject_onward_spec_newcand_inbody.ll`.
* A NEW candidate with a **non-i32 tainted arg** (`g((i16)%out)`) →
  `classifyCandidate` step (A) `kMsgFpAbi` (Rule 15, the i32-handle ABI). Fixture:
  `reject_onward_spec_newcand_fparg.ll`.
* A NEW candidate reading a **`%out2` control rail** (not in reseed) → not detected
  → `kMsgUnknownCallee` (a yn71 follow-on; safe over-decline, no broken module —
  already asserted in yn71's `detectAndLowerOnwardControl` comment).
* A **round-1** candidate reading reseed → owned by `replanReseedSpecialization`
  (`i16arg` FpAbi, `qqcmp` Q+Q late-decline); 9paa skips it via (a)/(b).

## 6. Soundness (why the wider detection cannot silent-miscompile)

* `scanBody` is MASK-INDEPENDENT and identical to round 1 (Rule 14 reuse), so a
  detected NEW candidate is provably liftable exactly as a round-1 one; the ONE
  mask-dependent gate (`classifyCandidate` step A, every tainted arg is an i32
  handle) runs on the concrete round-2 mask.
* `Site` is a STABLE pointer: `RegionFlatten` splices the merge tail (MOVES the
  call, never erases it), and the yn71 control re-runs / by-ref re-run never erase a
  plain candidate call — the invariant `shouldSpecialize` already relies on.
* The driver's existing depth-first 6.3 transitive machinery specializes any inner
  call the wider mask newly taints (an inner clone + its void `_unc` twin reversed
  in the outer Bennett wrap) — no new transitive code (covered by
  `accept_onward_spec_transitive.ll`, reused).
* The D2 anti-miscompile: the clone reads `%out` as a bare-QQ handle
  (`cq_template_mul_i32(h,h)`), NEVER as a `_hl` classical literal reading the
  qubit-handle tag — proven by the e2e golden's trace.

## 7. Fixtures (Rule 12) + e2e

* `control_classical_call_arm_accept_onward_spec_newcand.ll` — the flip: `g(%out)`
  (single arg, all-classical at round 1) → `@__cq_q_g_1`, bare-QQ `mul`, region
  accepts, no `_hl`, no unknown-callee (replaces the deleted `reject_…_newcand.ll`).
* `control_classical_call_arm_reject_onward_spec_newcand_inbody.ll` — redetect
  declines a NEW candidate with in-body control (`kMsgInBodyControl`), NO
  `unknown callee` (Diagnosed dedup).
* `control_classical_call_arm_reject_onward_spec_newcand_fparg.ll` — redetect
  step-A `kMsgFpAbi` on a non-i32 tainted arg, NO `unknown callee`.
* UNCHANGED declines: `reject_onward_spec_i16arg.ll` (re-plan FpAbi),
  `reject_onward_spec_qqcmp.ll` (re-plan Q+Q late) — the re-plan boundaries; 9paa
  skips them via (a)/(b).
* e2e `e2e-slice-control-spec-newcand` (`run_slice_multi.sh`, reuses
  `classical_call_under_control_lib.c`): `int y=5; if(q>3) y=ext_f(7); z=qsq(y);
  measure(z)` — `qsq(%out)` is a NEW candidate, cloned `@__cq_q_qsq_1`, its `mul`
  reading `%out` (h2) as a HANDLE. The only layer that LINK-proves the clone +
  `cq_template_mul_i32` + `_unc` twin resolve (Rule 2/16).

## 8. Follow-ons

* Round-2 spec DETECTION off a **yn71 control-produced `%out2` rail** — **NOW HANDLED
  by bd afmv** (2026-07-05): afmv moved the reseed computation to AFTER the yn71
  control fixpoint, so `%out2` rails are in the reseed set and 9paa's redetect (and the
  0vvq re-plan) cover a candidate reading a `%out2` rail. See
  `afmv-chained-control-spec-replan-PRD.md`. The ordering note in §4 above is
  superseded accordingly: the redetect still runs after the control fixpoint (the
  broken-module hazard stays closed), but the reseed set now includes `%out2`.
* A NEW candidate whose RESULT feeds an onward control region (candidate→control
  cascade) — still out of scope; result→measure/ret only. Safe over-decline.
