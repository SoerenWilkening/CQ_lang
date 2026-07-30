; spec_reject_fp_select_fcmp_fp128.ll — DECLINE (bd tkmn Inc 1 decline matrix).
; The fcmp-condition widening admits the condition COMPARE, never a compare at a
; width with no template: `fp128` is outside the YAML fcmp grid {f16,f32,f64,f80},
; so there is no `cq_template_fcmp_olt_f128_hl` to mint and the shape must stay
; loud. The select RESULT here is a perfectly in-scope `double` — the point of
; the fixture is that the CONDITION's operand width is an INDEPENDENT axis from
; the result width the whitelist above gates.
;
; WHICH GATE FIRES (measured, and deliberately recorded because naming the wrong
; clause is how containment arguments in this file have been wrong before): the
; message below is the `scanBody` DATA-OP whitelist rejecting the `fcmp fp128`
; INSTRUCTION itself ("unsupported width"), NOT `isLiftableFpSelect`'s own
; compare-width clause — the condition compare is an instruction in the callee
; body, so the data-op gate reaches it first regardless of the select. The clause
; in `isLiftableFpSelect` is defense in depth, kept so that predicate is
; self-contained rather than silently coupled to another gate's reachability.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported width)
; CHECK-NOT: cqrt_copy_f64_controlled
; CHECK-NOT: cq_template_fcmp
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %x  = sitofp i32 %n to double
  %xe = fpext double %x to fp128
  %c  = fcmp olt fp128 %xe, 0xL00000000000000000000000000000000
  %a  = select i1 %c, double 1.000000e+00, double %x
  %r  = fptosi double %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
