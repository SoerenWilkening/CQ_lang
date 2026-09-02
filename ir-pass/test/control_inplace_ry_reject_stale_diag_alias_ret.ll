; control_inplace_ry_reject_stale_diag_alias_ret.ll — DECLINE: a diagonal alias of
; the rotated register ESCAPES via `ret` after the region (control-in-place-PRD §4
; R6; bd test_C_libtooling-drbq Inc 1, finding J).
;
; Same wire, same defect as ..._stale_diag_alias_forward.ll, a different consumer
; kind: R6 is a rule about USERS, not about measurement. The caller receives a
; handle whose register the callee relabelled after the SSA name it returned was
; taken — and `ret` is an ESCAPE, so nothing downstream can even re-derive the
; post-region name.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r    = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %mark = call i32 @cq_phi_si32(i32 %r, double 1.000000e-01)
  %c    = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %d  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mark
}
