; lowering_volatile_scalar_promote_fpphi_tainted.ll — ACCEPT (bd vyqi, W5;
; FORMERLY the bd zco4 SAFETY-NET DECLINE PIN
; lowering_reject_volatile_scalar_promote_fpphi_tainted.ll): the promotion's
; most important IR PRODUCT, end-to-end. A volatile fp accumulator stored on
; BOTH arms of a TAINTED branch and reloaded after the merge — the distilled
; e_log10l.c `z` shape (`if (frac < SQRTH) z = ...; else z = ...`).
; promoteVolatileScalarLocals fires (clears volatile + PromoteMemToReg),
; minting the sole 2-incoming fp merge phi under tainted control. Pre-W5 that
; phi loud-declined `control flow under quantum control` (byte-identical to
; its non-volatile mem2reg twin) — the zco4 Inc-1 finding that spawned the
; fp-merge investigation. W5 closes the gap: the promoted diamond is claimed
; (sole 2-incoming scalar-fp phi, distinct incomings), PredMux flattens it to
; a tainted fp select, and the kjd1 controlled-copy merge lowers it — the
; SAME pipeline the multi-phi/nested variants (and the real log10l z-merge,
; a 3-phi merge) already rode. Promotion→flatten→copy, no route, no decline:
; the volatile-single-accumulator idiom class ("***CAUTION***" bodies with
; ONE guarded scalar) is now covered end-to-end.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='alloca double' --implicit-check-not='load volatile' --implicit-check-not='store volatile' --implicit-check-not='br i1' --implicit-check-not='phi double' < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %z = alloca double, align 8
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp olt double %q, 5.000000e-01            ; TAINTED condition
  br i1 %c, label %lo, label %hi
lo:
  %a = fadd double %q, -5.000000e-01               ; z = q - 0.5   (one arm)
  store volatile double %a, ptr %z, align 8
  br label %merge
hi:
  %b = fmul double %q, 2.000000e+00                ; z = q * 2     (other arm)
  store volatile double %b, ptr %z, align 8
  br label %merge
merge:
  %zv = load volatile double, ptr %z, align 8      ; promotion → sole fp merge phi
  %m = call double @cq_measure_f64(double %zv)
  ret double %m
}

; Promotion fired (no alloca/volatile survives), the exposed sole-phi fp merge
; flattened, and the kjd1 controlled-copy merge lowered it.
; CHECK-DAG: call i32 @cq_template_fadd_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double -5.000000e-01)
; CHECK-DAG: call i32 @cq_template_fmul_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 2.000000e+00)
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f64_hl(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[OUT]])
