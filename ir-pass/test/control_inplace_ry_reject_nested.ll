; control_inplace_ry_reject_nested.ll — DECLINE: a rotation arm inside a DEPTH-2
; nest (control-in-place-PRD §4 R7 / §8; bd test_C_libtooling-drbq).
;
;     if (q > 5) { if (q < 9) r = cq_theta(r, .9); }
;
; The 4.3 nest has its own emitter (`NestedRouteEmit`, flag-per-level routing over
; two work rails) and its own detector (`recoverRegionTree`), neither of which
; knows this arm class — a nest is dispatched by `handleBranchRegion` BEFORE
; `classifyArms` ever runs, so the in-place clause is not even consulted. The nest
; classifier walks a PHASE spine, finds a `cq_theta` where a `cq_phi` chain should
; be, and declines. Nests keep the route (owner Q8: "nesting is a different
; story").
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; MIRRORED CHARACTER-FOR-CHARACTER (Rule 12). The earlier
; `error{{.*}}under quantum control` matched EVERY diagnostic in the family —
; measured green against the tainted-angle fixture's stderr — so it asserted
; "something declined", not "this fence declined" (round-1 review, lens L6 §5).
; CHECK: error{{.*}}impure phase arm under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r  = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %mid ], [ %r, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
