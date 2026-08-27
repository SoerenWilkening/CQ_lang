; control_swap_reject_seq_ifelse_second.ll — DECLINE (bd hcrg decline
; partition): a sequential chain whose SECOND region is an IF/ELSE.
;
; This pins the exact edge of what hcrg bought. A diamond FOLLOWER lowers
; (control_swap_accept_seq_ifelse_then_diamond.ll) because a diamond reads its
; routed handle straight off the merge phi's Pred EDGE — which is the previous
; region's merge phi, an i32 the earlier region's emit RAUWs to the live handle.
; An if/else has NO Pred edge, so `emitRegion` derives its base by walking the
; arm gate's phase spine (`phaseSpineBase`) — and that walk bottoms at the
; previous region's merge PHI. `isValueChangingOp` reads a `phi` as "any other
; instruction defines a new basis value" and ArmClassify declines it as an
; out-of-arm value contribution.
;
; So the boundary is NOT "sequential regions"; it is "a follower whose routed
; base is a phi". An if/else in FIRST position is fine — the accept fixture
; above opens with one. This is an over-DECLINE, and deliberately left standing:
; lifting it is derived-base work on ArmClassify (a Rule-13 file), independent of
; the emission-ordering change, and over-declining is always safe.
;
; MEASURED both ways: the same if/else in isolation LOWERS; put a region in
; front of it and it declines. That difference, not the message, is what this
; file is asserting.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %c, double %d) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  %g1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %m1
m1:
  %p1 = phi i32 [ %g1, %arm1 ], [ %q, %entry ]
  %c2 = icmp sgt i32 %p1, 3
  br i1 %c2, label %t2, label %f2      ; an IF/ELSE follower — no Pred edge
t2:
  %g2 = call i32 @cq_phi_si32(i32 %p1, double %c)
  br label %m2
f2:
  %g2b = call i32 @cq_phi_si32(i32 %p1, double %d)
  br label %m2
m2:
  %p2 = phi i32 [ %g2, %t2 ], [ %g2b, %f2 ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: value-arm swap-route under quantum control
