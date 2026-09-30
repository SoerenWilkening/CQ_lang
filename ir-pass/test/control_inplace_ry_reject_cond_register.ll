; control_inplace_ry_reject_cond_register.ll — the arm's Ry changes the
; condition's own register (bd test_C_libtooling-drbq).
;
; The current flag strip recomputes q > 5. After an Ry on q, that recomputation
; cannot recover the predicate's earlier basis value, so the existing lowering
; would strip the wrong flag. This fixture pins the loud condition-wire fence.
; It does not establish that every implementation of this program is forbidden.
; The retired diagonal alias hops no longer occur in this input.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %qt = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
