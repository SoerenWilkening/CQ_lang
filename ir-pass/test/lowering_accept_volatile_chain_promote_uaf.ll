; lowering_accept_volatile_chain_promote_uaf.ll — bd r2j3.18: a volatile local
; stored from a load of ANOTHER promotable volatile local (`volatile double b = x;
; volatile double a = b;`, openlibm b_tgamma.c's TRUNC chain). promoteVolatile-
; ScalarLocals collected the stored values before PromoteMemToReg, which erases
; the load `%vb`; the raw pointer then dangled into deleteDeadCones (heap
; corruption: 29/483 census probes crashed under -j6, every probe deterministic
; under the lifo allocator). The stored values are now tracking handles. The
; lifo RUN is the witness: it crashed (SIGSEGV) before the fix. The classical
; function promotes to plain SSA either way.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: env CQ_OPT_DEBUG_ALLOC=lifo %debugalloc-cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.lifo.ll
; RUN: %filecheck %s < %t.lifo.ll
;
; CHECK:      define double @classical(double %x)
; CHECK-NEXT:   %r = fadd double %x, 1.000000e+00
; CHECK-NEXT:   ret double %r
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @classical(double %x) {
  %a = alloca double, align 8
  %b = alloca double, align 8
  store volatile double %x, ptr %b, align 8
  %vb = load volatile double, ptr %b, align 8
  store volatile double %vb, ptr %a, align 8
  %va = load volatile double, ptr %a, align 8
  %r = fadd double %va, 1.000000e+00
  ret double %r
}

define double @example(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}
