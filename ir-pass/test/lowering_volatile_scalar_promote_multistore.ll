; lowering_volatile_scalar_promote_multistore.ll — ACCEPT (bd zco4; formerly the
; bd etiq DECLINE pin lowering_reject_volatile_local_two_stores.ll). A volatile
; scalar with MORE THAN ONE store is NOT the etiq const-fold's shape (that fold
; requires exactly one Constant store — it still correctly does not fire here).
; But promoteVolatileScalarLocals (the mem2reg sibling) DOES handle a multi-store
; accumulator: PromoteMemToReg forwards each store to the following load in
; program order, so the loaded value is the SECOND (last) store's constant. The
; volatile scalar lives inside the tainted `arm` region (the claimable nested-W1
; skeleton of lowering_volatile_scalar_promote.ll); once promoted, the region has
; no volatile access, flattens, and lowers via the controlled-copy merge — exactly
; the promotion-under-tainted-control that log10l's `z` accumulator exercises. The
; order-respecting value (0x3E00.., the last store — NOT the first store 0x41F0..,
; which a buggy fold would pick) proves promotion, not a mis-fold.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %vd = alloca double, align 8
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  store volatile double 0x41F0000000000000, ptr %vd, align 8
  store volatile double 0x3E00000000000000, ptr %vd, align 8   ; last store wins
  %t = load volatile double, ptr %vd, align 8
  %u = fmul double %q, %t
  %c2 = fcmp ogt double %q, -1.000000e+00
  br i1 %c2, label %arm2, label %join
arm2:
  %v2 = fadd double %u, 1.000000e+00
  br label %join
join:
  %hi = phi double [ %v2, %arm2 ], [ %u, %arm ]
  br label %merge
merge:
  %r = phi double [ %hi, %join ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK:     call i32 @cq_template_fmul_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 0x3E00000000000000)
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call double @cqrt_measure_f64(
; CHECK-NOT: alloca double
; CHECK-NOT: load volatile
; CHECK-NOT: store volatile
; CHECK-NOT: 0x41F0000000000000
