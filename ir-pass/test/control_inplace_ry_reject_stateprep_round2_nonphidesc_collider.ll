; control_inplace_ry_reject_stateprep_round2_nonphidesc_collider.ll — DECLINE (F2).
;
; THE ISOLATING CONTROL of the ROUND-2 REACHABILITY PAIR (bd
; `test_C_libtooling-om35`, round-2 Rule-13 review §1b). Its twin is
; `control_inplace_ry_stateprep_round2_phidesc_collider_accept.ll`, which is THIS
; module with ONE OPERAND changed: there `%mz = zext i32 %MB to i64` reads the
; region's own state-prep merge phi, here it reads `%q`, the source rail. Nothing
; else differs.
;
; WHAT THE PAIR PINS, AND WHY IT IS NOT REDUNDANT WITH THE FLAT ACCEPT/DECLINE
; PAIR ALREADY IN THE TREE. `detectControlRegions` + `lowerControlRegions` run
; TWICE (`repropagateControlMerges` re-seeds taint from the 6.5/4.5 `%out` rails
; and runs a second full round to a fixpoint), and EVERY stage in that window owes
; the L1 question. The phi-descendant conjunct is computed inside F2, which means
; it is recomputed in round 2 over a user graph round 1's EMITTERS have rewritten
; — the L1 PREDICATE species. Before that hazard can be argued about at all, the
; window has to be shown to EXIST: this pair is the only thing in the tree
; pinning that F2 is REACHED in round 2 and that the conjunct fires there.
;
; HOW THE ROUND-2 CALL IS FORCED. `%out` is the merge of a **6.5 classical-call
; arm** (`call fastcc @f`), so it is CLASSICAL in round 1 — `icmp eq i32 %out, 13`
; is not a tainted branch and the state-prep region below it is NOT detected in
; round 1. Only after `repropagateControlMerges` re-seeds taint from the emitted
; out-rail does that region exist. On the subject binary `CQ_CTRL_DBG=1` prints
; this file's decline anchor as `%c2 = icmp eq i32 %out1, 13` — **the operand name
; `%out1` is the round-1-EMITTED out-rail**, which is the proof that the F2 call
; doing the declining is the round-2 one and not a round-1 leftover.
;
; WHY THE i64 HOP. It keeps the pinned intermediate (`%dd`, which is itself
; {0}-valued on the true edge) off the TEST's `V->getType() == Seed->getType()`
; clause, so the value that reaches the test is the trunc `%zm` and not `%dd`.
; Two earlier attempts at this shape were VACUOUS for exactly that reason and are
; recorded as such in `trackF/review_r2_probes` (`r1c`, `r4`).
;
; MEASURED on all three binaries of the increment: this file DECLINES on the
; ORACLE (`f7b65d8c…`), on the un-narrowed subject (`147cb3d6…`) and on the
; narrowed subject (`96fdd3a9…`). Its twin declines only on the ORACLE.
;
; ⚠ RETIREMENT TRIGGER (L8): the day `repropagateControlMerges` stops running a
; SECOND detect+lower round — or the day the 6.5 classical-call arm stops being
; classical in round 1 — this pair no longer pins what its headers claim. Do not
; delete it then; re-derive a round-2-reaching skeleton first, because the L1
; window it witnesses is the one that produced bd `9pum` / `r9e5` F-B1R2-1 and
; bd `b6ap` F-B6-1.
;
; ⚠ The IR-text `CHECK-NOT`s below are VACUOUS BY CONSTRUCTION and are kept only
; as belt-and-braces: a `DS_Error` decline writes 0 bytes to stdout, so what pins
; this file is the `not` inversion on the RUN line plus the message match
; (Rule 12(b)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define internal fastcc i32 @f(i32 %x) unnamed_addr #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}
define i32 @example() {
entry:
  %kp = alloca i32, align 4
  store volatile i32 4, ptr %kp, align 4
  %k = load volatile i32, ptr %kp, align 4
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c1 = icmp eq i32 %q, 1
  br i1 %c1, label %arm1, label %m1
arm1:
  %r = call fastcc i32 @f(i32 %k) #1
  br label %m1
m1:
  %out = phi i32 [ %r, %arm1 ], [ 0, %entry ]
  %c2 = icmp eq i32 %out, 13
  br i1 %c2, label %armB, label %mB
armB:
  %tb = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %mB
mB:
  %MB = phi i32 [ %tb, %armB ], [ 0, %m1 ]
  %dz = zext i32 %out to i64
  %dd = add i64 %dz, -13
  %mz = zext i32 %q to i64
  %pm = mul i64 %dd, %mz
  %zm = trunc i64 %pm to i32
  %x0 = call i32 @cq_measure_si32(i32 %q)
  %x1 = call i32 @cq_measure_si32(i32 %MB)
  %x2 = call i32 @cq_measure_si32(i32 %zm)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  ret i32 %s2
}
attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind willreturn memory(none) }

; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; CHECK-NOT: cqrt_alloc_i32
