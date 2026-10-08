; lowering_volatile_scalar_promote_runtime.ll — ACCEPT (bd zco4; formerly the bd
; etiq DECLINE pin lowering_reject_volatile_local_nonconst_store.ll). A volatile
; scalar whose store value is a RUNTIME (non-Constant) CLASSICAL value is not the
; etiq const-fold's shape (that fold requires a Constant store — it still
; correctly does not fire). But promoteVolatileScalarLocals handles it:
; PromoteMemToReg forwards the runtime store `%rt` to the load, and the tainted
; use `fmul %q, %rt` lowers with `%rt` as the classical literal operand of the
; mixed handle+literal template — never allocated to a qubit (Rule 3). A TAINTED
; store value is structurally excluded (the belt-and-braces taint check + the
; store-value never being a plain classical), so a quantum shadow scalar is never
; promoted; here `%rt` is a classical argument. The scalar lives inside the
; tainted `arm` region and, once promoted, flattens and lowers via the
; controlled-copy merge.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0, double %rt) {
entry:
  %vd = alloca double, align 8
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  store volatile double %rt, ptr %vd, align 8   ; runtime classical value
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

; CHECK:     %rt.stable = freeze double %rt
; CHECK:     call i32 @cq_template_fmul_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double %rt.stable)
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call double @cqrt_measure_f64(
; CHECK-NOT: alloca double
; CHECK-NOT: load volatile
; CHECK-NOT: store volatile
