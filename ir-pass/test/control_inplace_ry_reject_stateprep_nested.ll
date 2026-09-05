; control_inplace_ry_reject_stateprep_nested.ll — DECLINE: a DEPTH-2 nest whose
; inner arm is a state prep.
;
; The 4.3 depth-2 nested path (`RegionTreeDetect` + `NestedRouteEmit`) lowers
; HOMOGENEOUS PHASE nests only — it routes, and a route cannot carry an Ry
; (`Ry(θ)|0> != |0>` leaves the inactive work rail dirty and entangled, Rules
; 6/8). Measured IDENTICAL on the pre-Inc-4 oracle, so this row is untouched by
; Inc 4.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}impure phase arm under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %mid ], [ 0, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
