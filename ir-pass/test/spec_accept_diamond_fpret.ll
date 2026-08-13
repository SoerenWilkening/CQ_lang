; spec_accept_diamond_fpret.ll — Phase 6 / issue 5po2 I1 (Rule-13 over-accept fix):
; an fp-RETURN two-phi value diamond in a lifted callee. `helper` returns `double`
; through a 2-phi diamond; handed a tainted i32 condition arg + tainted f64 data
; arg it lifts into a clone whose signature is REWRITTEN to i32 (the runtime handle
; is always i32, Rule 15) with an fp `cqrt_copy_f64` copy-out — NOT a `double`-
; declared clone with a mistyped `ret i32` (the broken module the multi-block
; `predictReturnTainted` misprediction produced before the fix: it read only the
; entry-block terminator, a `br` for a diamond, so it under-predicted "classical"
; and `cloneFor` kept the fp return type). The fp arm muxes lower via
; `cqrt_copy_f64_controlled` and the whole clone Bennett-wraps + reverses cleanly.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)

define double @helper(i32 %s, double %b) {
entry:
  %c1 = icmp sgt i32 %s, 5
  br i1 %c1, label %then, label %else
then:
  %a1 = fadd double %b, 1.0
  %d1 = fadd double %b, 2.0
  br label %merge
else:
  %a2 = fadd double %b, 3.0
  %d2 = fadd double %b, 4.0
  br label %merge
merge:
  %pa = phi double [ %a1, %then ], [ %a2, %else ]
  %pd = phi double [ %d1, %then ], [ %d2, %else ]
  %r  = fadd double %pa, %pd
  ret double %r
}

define i32 @example(i32 %u, double %v) {
entry:
  %qs = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %qb = call double @cq_theta_f64(double %v, double 5.000000e-01)
  %r  = call double @helper(i32 %qs, double %qb)
  %ri = fptosi double %r to i32
  %m  = call i32 @cq_measure_si32(i32 %ri)
  ret i32 %m
}

; Clone signature rewritten to i32 (both args + return are i32 handles — the fix;
; it was `double` with a mistyped `ret i32` before). The fp arm muxes use the fp
; controlled copy, the escaping copy-out is fp-to-handle, and the terminator is a
; consistent `ret i32`. The 2nd RUN line (`opt -passes=verify`) is the real guard:
; it FAILED on the pre-fix broken module (return-type/signature mismatch). The
; CHECK-LABEL scopes the negative checks to the clone body only (the original
; unspecialized `helper` legitimately still carries `ret double`).
; CHECK-LABEL: define internal i32 @__cq_q_helper_{{[0-9]+}}(i32 %s, i32 %b)
; CHECK:       call void @cqrt_copy_f64_controlled(
; CHECK:       call void @cqrt_copy_f64(i32
; CHECK:       ret i32
; CHECK-NOT:   ret double
; CHECK-NOT:   br i1
; CHECK-NOT:   = phi
; CHECK-NOT:   = select
