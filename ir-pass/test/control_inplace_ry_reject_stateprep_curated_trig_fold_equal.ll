; control_inplace_ry_reject_stateprep_curated_trig_fold_equal.ll — DECLINE (bd test_C_libtooling-dm7f.18).
; The negative twin of control_inplace_ry_accept_stateprep_curated_trig_fold.ll: the
; arm's seed is EXACTLY atan(0.5) (0x3FDDAC670561BB50), the value clang would have produced
; by folding the `atan(q)` LIBCALL on the edge where `q == 0.5` (a `-fmath-errno`
; frontend, Linux, emits and folds it). F2 must still see that equality through the
; new host fold and decline; a blanket accept of the curated trig ids would pass the
; positive twin and fail here. On darwin clang emits `@llvm.atan.f64` and folds
; nothing, so there this decline is a (bit-exact, contrived) over-decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.tan.f64(double)
declare double @llvm.asin.f64(double)
declare double @llvm.acos.f64(double)
declare double @llvm.atan.f64(double)

define double @t_atan_eq(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %z = call double @llvm.atan.f64(double %q)
  %c = fcmp oeq double %q, 5.000000e-01
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 0x3FDDAC670561BB50, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 0x3FDDAC670561BB50, %entry ]
  %m1 = call double @cq_measure_f64(double %rm)
  %m2 = call double @cq_measure_f64(double %z)
  %s = fadd double %m1, %m2
  ret double %s
}
