; spec_result_propagates.ll — Phase 6.1 WI-1.9 (return-taint, true case, §2.7).
; The caller consumes the retargeted clone result in a FURTHER tainted op
; (`%s = add %r, %q2`). Because the clone's return derives from the tainted
; param (`ReturnTainted = true`), `specialize` keeps `%r` in the ORIGINAL
; `taint.Tainted`, so the downstream `add` lowers to `cq_template_add_i32` — the
; specialized call composes with the rest of the quantum program.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @triple(i32 %a) {
entry:
  %y = mul i32 %a, 3
  ret i32 %y
}

define void @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %r = call i32 @triple(i32 %q)
  %s = add i32 %r, %q2
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}

; The retargeted result `%r` stays tainted → the caller's `add` lowers to a QQ
; template reading `%r` and the second handle (proving return-taint re-marked).
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_triple_1(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_add_i32(i32 %[[R]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     define internal i32 @__cq_q_triple_1(i32 %a)
;
; The caller's `add` did NOT stay a raw classical add.
; CHECK-NOT: %s = add i32
