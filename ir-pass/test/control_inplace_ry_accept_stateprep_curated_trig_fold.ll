; control_inplace_ry_accept_stateprep_curated_trig_fold.ll — ACCEPT (bd test_C_libtooling-dm7f.18).
; State-prep fence F2 asks whether clang could have substituted the arm's classical
; seed from a value derived from the condition register pinned on that edge
; (`q == 0.5`). The register also feeds a curated trig intrinsic. LLVM 19 folds
; `llvm.sin`/`llvm.cos` but not `llvm.tan`/`asin`/`acos`/`atan` (added to the
; curated set by 66f18d19), so F2 took its conservative branch and declined
; "state prep seed is proven equal to the condition register" for a seed (0.123)
; that equals none of tan/asin/acos/atan(0.5). F2 now folds the four f64 ids with
; the host libm, as LLVM's ConstantFolding folds the `tan`/`asin`/`acos`/`atan`
; libcalls a `-fmath-errno` frontend emits (NaN/inf results stay unfolded), and
; compares.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define double @t_tan(
; CHECK:       call void @cqrt_ry_f64_controlled(
; CHECK-LABEL: define double @t_asin(
; CHECK:       call void @cqrt_ry_f64_controlled(
; CHECK-LABEL: define double @t_acos(
; CHECK:       call void @cqrt_ry_f64_controlled(
; CHECK-LABEL: define double @t_atan(
; CHECK:       call void @cqrt_ry_f64_controlled(

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.tan.f64(double)
declare double @llvm.asin.f64(double)
declare double @llvm.acos.f64(double)
declare double @llvm.atan.f64(double)

define double @t_tan(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %z = call double @llvm.tan.f64(double %q)
  %c = fcmp oeq double %q, 5.000000e-01
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 1.230000e-01, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 1.230000e-01, %entry ]
  %m1 = call double @cq_measure_f64(double %rm)
  %m2 = call double @cq_measure_f64(double %z)
  %s = fadd double %m1, %m2
  ret double %s
}
define double @t_asin(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %z = call double @llvm.asin.f64(double %q)
  %c = fcmp oeq double %q, 5.000000e-01
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 1.230000e-01, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 1.230000e-01, %entry ]
  %m1 = call double @cq_measure_f64(double %rm)
  %m2 = call double @cq_measure_f64(double %z)
  %s = fadd double %m1, %m2
  ret double %s
}
define double @t_acos(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %z = call double @llvm.acos.f64(double %q)
  %c = fcmp oeq double %q, 5.000000e-01
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 1.230000e-01, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 1.230000e-01, %entry ]
  %m1 = call double @cq_measure_f64(double %rm)
  %m2 = call double @cq_measure_f64(double %z)
  %s = fadd double %m1, %m2
  ret double %s
}
define double @t_atan(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %z = call double @llvm.atan.f64(double %q)
  %c = fcmp oeq double %q, 5.000000e-01
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 1.230000e-01, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 1.230000e-01, %entry ]
  %m1 = call double @cq_measure_f64(double %rm)
  %m2 = call double @cq_measure_f64(double %z)
  %s = fadd double %m1, %m2
  ret double %s
}
