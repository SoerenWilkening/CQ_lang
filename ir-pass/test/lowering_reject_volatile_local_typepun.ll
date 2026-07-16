; lowering_reject_volatile_local_typepun.ll — DECLINE PIN (bd etiq): the
; volatile-const LOCAL fold must NOT fire for a load whose TYPE differs from
; the stored constant's type — a type-punned read (`*(volatile long *)&vd`)
; is a different idiom from the openlibm rounding constant, and the fold's
; proof is exact-type only (the global fold reads through the initializer
; via ConstantFoldLoadFromConst; the alloca sibling deliberately stays
; narrower — over-declining is safe). The region skeleton is the claimable
; nested-W1 shape of lowering_volatile_local_fold.ll (the punned word rides
; a classical sitofp), so the volatile pair is the region's ONLY blocker.
; Unfolded, it blocks the tainted region (PredMux E4) and declines loudly.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
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
  %p = load volatile i64, ptr %vd, align 8      ; type-punned read — no fold
  %d = sitofp i64 %p to double
  %u = fmul double %q, %d
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

; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
