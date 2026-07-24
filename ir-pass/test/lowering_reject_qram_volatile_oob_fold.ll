; lowering_reject_qram_volatile_oob_fold.ll — DECLINE PIN (3c6m.14 L6 Inc 3,
; Rule-13 clearance hardening, LENS-1): the OOB twin of the passing
; lowering_qram_volatile_fold.ll. The `atanlo` volatile-cast load reads byte
; offset 40 — PAST THE END of the 32-byte `[4 x double]` array.
; `ConstantFoldLoadFromConst` treats bytes past the initializer as POISON (a
; non-null constant), so without a bounds guard the OOB volatile load would
; silently fold to `poison` instead of riding the decline. The fold now
; bounds-checks `[Off, Off+loadSize)` against the initializer and refuses, so
; the volatile load survives, blocks the region (E4 admits no volatile
; access), and it declines loudly. (An OOB volatile read is UB in C and never
; occurs in the injected openlibm bodies — twom1000 @0, atanlo[3] @24 are
; exactly in-bounds — but over-declining is safe.) The in-bounds @24 twin
; (lowering_qram_volatile_fold.ll) folds+lowers, making this red-green.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@twom1000 = internal global double 0x0170000000000000, align 8
@atanlo = internal constant [4 x double] [double 0x3C7A2B7F222F65E2, double 0x3C81A62633145C07, double 0x3C7007887AF0CBBD, double 0x3C91A62633145C07], align 16
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %t = load volatile double, ptr @twom1000, align 8
  %a = load volatile double, ptr getelementptr inbounds (i8, ptr @atanlo, i64 40), align 8
  %u = fmul double %q, %t
  %c2 = fcmp ogt double %q, -1.000000e+00
  br i1 %c2, label %arm2, label %join
arm2:
  %v2 = fadd double %u, %a
  br label %join
join:
  %hi = phi double [ %v2, %arm2 ], [ %u, %arm ]
  br label %merge
merge:
  %r = phi double [ %hi, %join ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; (bd vyqi, W5 re-label: the INNER flat fp diamond of the nested-W1 skeleton
; now flattens first — its sole-2-incoming fp merge phi is a claim witness —
; so the residual outer region declines UN-nested. The access above still
; blocks the fold/promotion and the region still declines LOUDLY; only the
; label narrowed from `nested control flow` to `control flow`.)
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
