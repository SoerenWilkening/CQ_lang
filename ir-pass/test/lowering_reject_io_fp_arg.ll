; lowering_reject_io_fp_arg.ll — DECLINE (Phase 7.6): a tainted floating-point
; `printf("%f", d)` argument. An fp value in a rail is the f64/angle silent-
; miscompile family — the recognized sink declines LOUDLY rather than tape an fp
; arg. Tested via `isFPOrFPVectorTy()` (not scalar-only `isFloatingPointTy`). This
; is a PERMANENT decline (PRD-7.6 §5).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare i32 @printf(ptr, ...)
@.f = private constant [3 x i8] c"%f\00"

define void @slice(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %r = call i32 (ptr, ...) @printf(ptr @.f, double %q)
  ret void
}

; CHECK: error{{.*}}cq I/O output sink: tainted argument is not a lowerable integer scalar
