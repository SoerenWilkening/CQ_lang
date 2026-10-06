; libm_bind_passthrough_erase.ll — bd 3c6m.72: a module with no quantum work
; that carries the injected bundle loses every `__cq_libm_*` body and table, and
; its classical calls keep their callee (owner ruling 2026-10-06). tools/cqc links
; the bundle only into a program that uses a CQ primitive, so a classical cqc
; program never carries it; this pins the pass-level backstop for `cq-opt` users
; and for a CQ program whose quantum work folds away.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=GONE < %t.ll
; CHECK:     define double @example(double %c)
; CHECK:     call double @llvm.sin.f64(double %c)
; GONE-NOT:  __cq_libm_
declare double @llvm.sin.f64(double)

define double @__cq_libm_sin(double %x) {
  %y = fmul double %x, 2.000000e+00
  ret double %y
}
@__cq_libm_tab = global double 1.0

define double @example(double %c) {
  %k = call double @llvm.sin.f64(double %c)
  ret double %k
}
