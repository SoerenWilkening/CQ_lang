; lowering_reject_volatile_local_gep_user.ll — DECLINE PIN (bd etiq): the
; volatile-const LOCAL fold walks DIRECT users only — any gep on the alloca
; (even at offset 0) forfeits the fold. The openlibm rounding idiom is a
; scalar local read back whole; an offset view is a different idiom, and the
; global fold's gep tolerance (constexpr geps into `constant` arrays) does
; not transfer: the local proof is exact-type, exact-address. The region
; skeleton is the claimable nested-W1 shape of
; lowering_volatile_local_fold.ll, so the volatile pair is the region's ONLY
; blocker: a fold that admitted the gep view would erase the store/alloca
; under the surviving gep'd load and break the module loudly. Unfolded, the
; volatile access blocks the tainted region (PredMux E4) and declines loudly.
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
  %gp = getelementptr inbounds i8, ptr %vd, i64 0   ; gep view — no fold
  %t = load volatile double, ptr %gp, align 8
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

; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
