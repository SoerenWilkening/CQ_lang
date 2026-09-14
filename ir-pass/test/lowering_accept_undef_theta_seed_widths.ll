; lowering_accept_undef_theta_seed_widths.ll — ACCEPT (bd z9t1). THE WIDTH
; SWEEP: the normalized seed is a zero OF THAT TYPE, not an `i32 0` coerced into
; whatever slot the suffix names.
;
; `Constant::getNullValue(Seed->getType())` is read off the OPERAND's own type,
; which `declMatchesPrototype` (TaintPropagation.cpp) has already proven equals
; the suffix's `T` — so no width table is consulted and no width can be missed.
; Three of the nine reachable types are pinned here and they are the three that
; could plausibly differ in spelling: an integer (`i32 0`), an IEEE double
; (`double 0.000000e+00`, i.e. +0.0 and NOT a bit-pattern) and the x86 80-bit
; extended (`x86_fp80 0xK00000000000000000000`, the one type whose literal
; spelling is not the obvious one).
;
; The other six (`i1`, `i8`, `i16`, `i64`, `half`, `float`) ride the same one
; line of code; `lowering_accept_undef_theta_seed_zero.ll` pins `i1` as the
; ruled customer's own width.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_ry_i32(
; CHECK:     call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_ry_f64(
; CHECK:     call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK:     call void @cqrt_ry_f80(
;
; No literal undef/poison survives in ANY of the three seed slots. Typed
; patterns, in their own whole-file prefix (Rule 12 hygiene (a)).
; RUN: %filecheck %s --check-prefix=NOUNDEF < %t.cqd0.ll
; NOUNDEF-NOT: i32 undef
; NOUNDEF-NOT: double undef
; NOUNDEF-NOT: x86_fp80 undef
; NOUNDEF-NOT: i32 poison
; NOUNDEF-NOT: double poison
; NOUNDEF-NOT: x86_fp80 poison

;
; *** THE WHOLE EMITTED STREAM, PINNED IN ORDER, WITH NOTHING ELSE ALLOWED. ***
; The two `--implicit-check-not` patterns carry a negative over the ENTIRE file
; between every pair of STREAM lines, so ANY extra emitted gate — an injected
; `cqrt_x` on a user register, a second `cqrt_ry`, a `cqrt_cswap`, a `cqrt_free`,
; a measurement the user did not write (Rule 5) — reddens this prefix wherever it
; is placed. MEASURED with `$SES/trackU/probes/impl/inject_u.py`, not asserted:
; strip this prefix and 11 of 17 mutations over two of these fixtures go MISSED
; (injected `cqrt_x`, extra `cqrt_free`, extra `cqrt_ry`, `cqrt_cswap`, swapped
; copy pair, extra measurement); with it, 0 MISSED of 67 over all nine. The
; patterns match CALL SITES only (`call {{.*}}@cqrt_`), so the module's trailing
; `declare` lines are untouched.
; RUN: %filecheck %s --check-prefix=STREAM \
; RUN:   --implicit-check-not='call {{.*}}@cqrt_' \
; RUN:   --implicit-check-not='call {{.*}}@cq_template_' < %t.cqd0.ll
; STREAM:      %h = call i32 @cqrt_alloc_i32(i32 0)
; STREAM:      call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; STREAM:      %h1 = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; STREAM:      call void @cqrt_ry_f64(i32 %h1, double 2.500000e-01)
; STREAM:      %h2 = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; STREAM:      call void @cqrt_ry_f80(i32 %h2, double 1.250000e-01)
; STREAM:      %m = call i32 @cqrt_measure_i32(i32 %h)
; STREAM:      %m3 = call double @cqrt_measure_f64(i32 %h1)
; STREAM:      %m4 = call x86_fp80 @cqrt_measure_f80(i32 %h2)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define i32 @example() {
entry:
  %qi = call i32 @cq_theta_si32(i32 undef, double 5.000000e-01)
  %qd = call double @cq_theta_f64(double poison, double 2.500000e-01)
  %ql = call x86_fp80 @cq_theta_f80(x86_fp80 undef, double 1.250000e-01)
  %mi = call i32 @cq_measure_si32(i32 %qi)
  %md = call double @cq_measure_f64(double %qd)
  %ml = call x86_fp80 @cq_measure_f80(x86_fp80 %ql)
  ret i32 %mi
}
