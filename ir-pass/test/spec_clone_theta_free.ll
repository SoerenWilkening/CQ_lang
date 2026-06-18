; spec_clone_theta_free.ll — Phase 6.1 WI-1.7: the clone lowers its own
; data ops INTERNALLY (during `specialize`, step 14), so no un-RAUW'd rotation
; survives into the clone when control returns to `lowerRotations` at `:110`
; (the DD-1 ordering risk). The accepted clone body has no `cq_theta` to begin
; with (a `cq_*` body is rejected, WI-1.5), and its arithmetic is fully lowered
; to `cq_template_*` BEFORE `:110` — there is no raw `add`/`mul` and no
; `@cq_theta` anywhere in the clone. The caller's own theta is lowered too, and
; the front-end intrinsic declaration is erased.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @poly(i32 %a) {
entry:
  %t = add i32 %a, 2
  %y = mul i32 %t, %a
  ret i32 %y
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @poly(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; The clone exists with internal linkage and its body is FULLY lowered: the add
; and the qq-mul are templates, then the Bennett wrap — no raw arithmetic.
; CHECK:     define internal i32 @__cq_q_poly_1(i32 %a)
; CHECK:     %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %a, i32 2)
; CHECK:     %[[MUL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %[[ADD]], i32 %a)
; CHECK:     call void @cqrt_copy_i32(
; CHECK:     ret i32
;
; No rotation source survives anywhere (the theta is lowered, the decl erased);
; no raw integer arithmetic remains in the CLONE (every op became a template).
; CHECK-NOT: @cq_theta_si32
; CHECK-NOT: = mul i32 %[[ADD]]
