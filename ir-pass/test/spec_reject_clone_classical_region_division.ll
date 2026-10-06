; spec_reject_clone_classical_region_division.ll — DECLINE, a goal-1 GAP (bd
; p3kd.7.2 decline fixture): a classical branch guarding a division by a CLASSICAL
; RUNTIME divisor, `d != 0 ? b + c/d : b`, in a lifted callee. Clone-mode PredMux
; if-converts classical control (owner ruling 2026-10-06), which would run the
; division on every path, including d == 0 where it is UB; `isSpeculatableDataflow`
; (E4) admits a division only by a nonzero constant, so the region leaves at
; `E4-dataflow` and the clone's size backstop declines loudly. Lowering it needs a
; total speculation (a safe divisor, `d == 0 ? 1 : d`, the chosen arm unchanged) or
; a per-path wrap; it is not physics.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function __cq_q_helper_001 i32 (i32, i32, i32): cq specialization: callee contains tainted control flow under quantum lift
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %c, i32 %d) {
entry:
  %nz = icmp ne i32 %d, 0
  br i1 %nz, label %div, label %m
div:
  %qt = sdiv i32 %c, %d
  %s = add i32 %b, %qt
  br label %m
m:
  %r = phi i32 [ %s, %div ], [ %b, %entry ]
  ret i32 %r
}

define i32 @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, i32 %u1, i32 %u2)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
