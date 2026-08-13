; spec_accept_fp_transitive.ll — bd 3c6m.54 (Rule-13 finding fix): TRANSITIVE fp
; specialization — an fp clone whose body CALLS another fp clone. `outer(x)` calls
; `inner(x)` (both `double(double)`), so `@__cq_q_outer_1`'s body holds a nested
; `@__cq_q_inner_1(i32)` call whose fp return is rewritten to an i32 handle. The
; Rule-13 reviewer caught that `retargetSite` REBUILDS that inner call (fresh
; i32-returning `CallInst`) but the new value was absent from the outer clone's
; `cloneTaint` — so the outer `fmul` read it as UNTAINTED and `ArithLowering` put
; the i32 handle in the fp LITERAL slot (`fmul_f64_hl(double 5.0, i32 %t)`), a
; BROKEN MODULE (opt verify abort). The fix migrates the rebuilt inner result's
; taint (+ `HandleWidth`) onto the new call in the drain loop, so the outer op sees
; a tainted i32 handle and emits the correct `fmul_f64_hl(i32 %t, double 5.0)`. The
; inner clone's void twin `@__cq_q_inner_1_unc` reverses it in LIFO. This pins the
; fp analog of `spec_accept_transitive.ll` (the integer twin).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @inner(double %x) {
  %y = fmul double %x, 3.000000e+00
  ret double %y
}

define double @outer(double %x) {
  %t = call double @inner(double %x)
  %u = fmul double %t, 5.000000e+00
  ret double %u
}

define double @example(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %r = call double @outer(double %q)
  %z = call double @cq_measure_f64(double %r)
  ret double %z
}

; The outer clone calls the inner fp clone (both i32 signatures), then multiplies
; its i32-handle result — the handle in the HANDLE slot, 5.0 in the LITERAL slot.
; CHECK:     define internal i32 @__cq_q_outer_1(i32 %x)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_inner_1(i32 %x)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f64_hl(i32 %[[T]], double 5.000000e+00)
; CHECK:     call void @cqrt_copy_f64(i32 %[[OP]], i32 %{{[a-zA-Z0-9_.]+}})
; LIFO reverse: the outer fmul `_unc`, then the inner clone's void twin (restores %x).
; CHECK:     call void @cq_template_fmul_f64_hl_unc(i32 %[[OP]], i32 %[[T]], double 5.000000e+00)
; CHECK:     call void @__cq_q_inner_1_unc(i32 %[[T]], i32 %x)
; CHECK:     ret i32
; The inner fp clone is itself a well-formed fp-ABI clone.
; CHECK:     define internal i32 @__cq_q_inner_1(i32 %x)
; CHECK-NOT: cq_template_fmul_f64_hl(double
