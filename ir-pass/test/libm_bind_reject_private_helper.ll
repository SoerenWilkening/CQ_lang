; libm_bind_reject_private_helper.ll — bd 3c6m.72, review round 1 finding 1: an
; `llvm.powi.f80.i32` call spells `powil`, and openlibm's ld80/e_powl.c has a
; PRIVATE `static long double powil(long double, int)` helper of powl with
; different semantics (LDBL_MAX where llvm.powi gives inf) and `fastcc`. The
; bundle keeps only math.h entry points external, and the binding refuses an
; internal body (LibmBinding.h), so the call stays an unknown callee, loudly,
; instead of lifting the wrong function.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)
declare x86_fp80 @llvm.powi.f80.i32(x86_fp80, i32)

define internal fastcc x86_fp80 @__cq_libm_powil(x86_fp80 %x, i32 %n) {
  ret x86_fp80 %x
}

define x86_fp80 @example(x86_fp80 %u0) {
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %p = call x86_fp80 @llvm.powi.f80.i32(x86_fp80 %q, i32 -3)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %p)
  ret x86_fp80 %m
}
