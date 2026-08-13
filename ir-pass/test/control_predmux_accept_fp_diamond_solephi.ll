; control_predmux_accept_fp_diamond_solephi.ll — ACCEPT (bd vyqi, W5): the flat
; both-arms-write fp if/else with a SOLE 2-incoming merge phi — the distilled
; log10l `z` accumulator shape the zco4 Inc-1 promotion exposed
; (`if (frac < SQRTH) z = a; else z = b;` with a tainted condition).
;
; Before W5 this was the LAST unclaimed flat acyclic tainted-control shape:
; PredMux's claim witnesses covered nested terminators, multi-phi merges and
; >2-incoming phis (the SAME body with a second merged variable already
; flattened and lowered), but the sole-2-incoming-phi diamond was left to the
; swap-route owners, whose 4.2 value path categorically declines an fp-typed
; merge (ArmClassify's fp fence — an fp merge is an ANGLE at a rotation
; consumer, but at a select/copy consumer it is DATA, the kjd1 un-staging). W5
; claims exactly this shape — sole 2-incoming scalar-fp merge phi, DISTINCT
; incomings — and the shipped substrate does the rest: flatten → tainted fp
; select → kjd1 controlled-copy merge (flag mint → |0⟩ out rail → two
; `cqrt_copy_f64_controlled`, the ¬flag one `cqrt_x`-bracketed → compare-`_inv`
; strip → one flag free). No new gate sequence, no new symbol (the fp copy
; family is the frozen kjd1 set); the whole quantum burden rides the cleared
; select substrate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='phi double' < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp olt double %q, 5.000000e-01            ; TAINTED condition
  br i1 %c, label %lo, label %hi
lo:
  %a = fadd double %q, -5.000000e-01               ; z = q - 0.5   (one arm)
  br label %merge
hi:
  %b = fmul double %q, 2.000000e+00                ; z = q * 2     (other arm)
  br label %merge
merge:
  %zv = phi double [ %a, %lo ], [ %b, %hi ]        ; sole 2-incoming fp merge
  %m = call double @cq_measure_f64(double %zv)
  ret double %m
}

; Both arm values compute unconditionally (speculated), the merge is the kjd1
; controlled-copy select: true value under the flag, false value under the
; X-bracketed ¬flag, strip, one free. The CFG diamond is gone.
; CHECK-DAG: call i32 @cq_template_fadd_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double -5.000000e-01)
; CHECK-DAG: call i32 @cq_template_fmul_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 2.000000e+00)
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f64_hl(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cq_template_fcmp_olt_f64_hl_unc(i32 %[[FLAG]], 
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[OUT]])
