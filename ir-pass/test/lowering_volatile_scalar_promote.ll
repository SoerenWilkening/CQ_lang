; lowering_volatile_scalar_promote.ll — ACCEPT (bd zco4): the volatile
; scalar-local SSA promotion, the mem2reg sibling of foldVolatileConstAllocaLoads
; (bd etiq). Where the etiq fold folds a single-CONSTANT-store volatile scalar to
; its constant, this promotes a MULTI-STORE COMPUTED accumulator — the
; OpenBSD/Moshier "***CAUTION***" idiom `volatile long double z` (e_log10l.c:125),
; an anti-reassociation guard on a private non-escaping scalar. clang's own
; mem2reg never promotes a volatile access, so at CQ's -O1 floor the tainted store
; `store volatile <tainted>, ptr %z` survives and declines at kMsgStore ("cq taint
; escape: tainted value stored to memory"). This straight-line accumulator
; (z = q; z = z+1; z = z*2) is the canonical shape: a single non-escaping f64
; scalar, every user a direct exact-type load/store or a lifetime marker, ≥1
; volatile, every load store-defined (no undef read). promoteVolatileScalarLocals
; clears isVolatile and runs PromoteMemToReg — the result is EXACTLY what clang's
; mem2reg builds for the same body with `volatile` removed. Dropping volatile is
; the same deliberate, idiom-invited choice etiq established (a private
; non-escaping scalar has no external observer; volatile's sole effect is to
; defeat FP reassociation, which the taint lowering never does). The tainted
; stores vanish and ordinary SSA taint flow lowers the remainder register-only.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

define double @probe(double %u0) {
entry:
  %z = alloca double, align 8
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %z)
  store volatile double %q, ptr %z, align 8          ; z = q       (tainted store)
  %z0 = load volatile double, ptr %z, align 8
  %z1 = fadd double %z0, 1.000000e+00                 ; z = z + 1
  store volatile double %z1, ptr %z, align 8
  %z2 = load volatile double, ptr %z, align 8
  %z3 = fmul double %z2, 2.000000e+00                 ; z = z * 2
  store volatile double %z3, ptr %z, align 8
  %z4 = load volatile double, ptr %z, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %z)
  %m = call double @cq_measure_f64(double %z4)
  ret double %m
}

; The accumulator promotes to SSA: the alloca, the volatile loads/stores and the
; lifetime markers are ALL gone; the reconstruction lowers register-only over the
; single rotation handle, verbatim in program order (never reassociated), ending
; in the measure. If promotion had failed, the first tainted store would have
; declined at kMsgStore instead.
; CHECK:     call i32 @cqrt_alloc_f64(double %u0)
; CHECK:     call void @cqrt_ry_f64(
; CHECK:     call i32 @cq_template_fadd_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 1.000000e+00)
; CHECK:     call i32 @cq_template_fmul_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 2.000000e+00)
; CHECK:     call double @cqrt_measure_f64(
; CHECK-NOT: alloca
; CHECK-NOT: load volatile
; CHECK-NOT: store volatile
; CHECK-NOT: llvm.lifetime
