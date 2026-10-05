; spec_reject_linkonce_callee.ll — DECLINE twin of spec_accept_odr_callee.ll
; (bd test_C_libtooling-p3kd.2). `linkonce` (linkonce_any, NOT linkonce_odr) is
; INTERPOSABLE: the linker may keep another TU's linkonce definition of the same
; name, and nothing makes that body equivalent to this one. Cloning this body
; would compute a unitary the linked program does not denote, so there is no
; implementation to lift (NORTHSTAR goal 1) and the loud decline stays,
; character for character. The body and caller are spec_accept_single.ll's; only
; the linkage differs from the accepted `linkonce_odr` spelling. `weak` is pinned
; by spec_reject_weak_callee.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define linkonce i32 @purefn(i32 %a) {
entry:
  %y = mul i32 %a, 7
  ret i32 %y
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r = call i32 @purefn(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK: error{{.*}}in function purefn{{.*}}cq specialization: callee has a non-link-exact definition (interposable/derefinable linkage); the linker may bind a different body
