; spec_intermediate_unc_libm_fdim.ll — ACCEPT, DISCHARGED (bd test_C_libtooling-p3kd.13):
; a math.h body INJECTED BY cqc, its lifted result uncomputed by its Bennett twin.
;
; PROVENANCE. The module is the real cqc stage-2 input (clang -O1 of the CQ TU,
; llvm-linked with build/libm/cq_libm.bc), reduced with `llvm-extract --recursive`
; to the three user functions plus the openlibm `__cq_libm_fdim` / `__cq_libm_isnan`
; bodies, debug info stripped:
;     #include <math.h>
;     double fdim_mul(double u, double e)    { double c = u; cq_theta(&c, .5);
;                                              double s = fdim(c, e) * 2.0;
;                                              return cq_measure(s); }
;     double fdim_nested(double u, double e) { ... double s = fdim(fdim(c, e), e) * 2.0; ... }
;     double fdim_cond(double u, double e, double k) { double c = u; cq_theta(&c, .5);
;                                              if (fdim(c, e) == k) cq_phi(PI);
;                                              cq_theta(&c, -0.5); return cq_measure(c); }
; `e` and `k` are RUNTIME classical operands (function parameters), never literals.
;
; WHAT main db4cf60a EMITTED: the `__cq_q___cq_libm_fdim_01` result (a basis record
; of c) stood allocated in all three — stage 2b: "3 template rail mint(s) ... left
; dirty". In @fdim_cond it also stood across the S-dagger `cq_theta(&c, -0.5)`,
; dephasing c: the owner's named case, a lifted call feeding a tainted branch.
;
; NOW: one mechanism for every consumer (CloneProducer.h) — the M-B interior
; partition owns the clone rail and discharges it LIFO with
; `@__cq_q___cq_libm_fdim_01_unc(out, x, e)`, synthesized once:
;   * @fdim_mul    — a template consumer (`fmul`);
;   * @fdim_nested — a clone consumed by a clone: the outer twin first, then the
;                    inner (whose consumer is the outer CALL, proven read-only);
;   * @fdim_cond   — the compare feeding the branch: the condition chain's rail is
;                    discharged after the recorded flag STRIP (the strip reads it)
;                    and before the S-dagger. There is no separate region-condition
;                    path (bd ln16 named one and it was never built): the same
;                    partition, the strip being its recorded consumer.
; The fdim clone body carries a `freeze` the speculation fence inserted; the twin
; re-executes it. Sound for a UB-free source program, the premise the inner-call
; twins already rest on (CloneProducer.h, "THE FREEZE").
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; SILENT-NOT: {{.}}

; CHECK-LABEL: define double @fdim_mul(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q___cq_libm_fdim_01(i32 %[[H]], double %1)
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f64_hl(i32 %[[R]], double 2.000000e+00)
; CHECK-NEXT: call void @__cq_q___cq_libm_fdim_01_unc(i32 %[[R]], i32 %[[H]], double %1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: call double @cqrt_measure_f64(i32 %[[S]])

; CHECK-LABEL: define double @fdim_nested(
; CHECK:      %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %0)
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @__cq_q___cq_libm_fdim_01(i32 %[[H2]], double %1)
; CHECK-NEXT: %[[B:[a-zA-Z0-9_.]+]] = call i32 @__cq_q___cq_libm_fdim_01(i32 %[[A]], double %1)
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f64_hl(i32 %[[B]], double 2.000000e+00)
; CHECK-NEXT: call void @__cq_q___cq_libm_fdim_01_unc(i32 %[[B]], i32 %[[A]], double %1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B]])
; CHECK-NEXT: call void @__cq_q___cq_libm_fdim_01_unc(i32 %[[A]], i32 %[[H2]], double %1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call double @cqrt_measure_f64(i32 %[[S2]])

; CHECK-LABEL: define double @fdim_cond(
; CHECK:      %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H3]], double 5.000000e-01)
; CHECK-NEXT: %[[R3:[a-zA-Z0-9_.]+]] = call i32 @__cq_q___cq_libm_fdim_01(i32 %[[H3]], double %1)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %[[R3]], double %2)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %[[F]], i32 %[[R3]], double %2)
; CHECK-NEXT: call void @__cq_q___cq_libm_fdim_01_unc(i32 %[[R3]], i32 %[[H3]], double %1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[R3]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H3]], double -5.000000e-01)

; One twin, after the clone, internal, void, `out` first:
; CHECK: define internal i32 @__cq_q___cq_libm_fdim_01(i32 %0, double noundef %1)
; CHECK: define internal void @__cq_q___cq_libm_fdim_01_unc(i32 %out, i32 %0, double noundef %1)
; CHECK: call void @cqrt_copy_f64(i32 %{{[a-zA-Z0-9_.]+}}, i32 %out)
; CHECK: ret void

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @fdim_mul(double noundef %0, double noundef %1) {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #4
  %4 = tail call double @fdim(double noundef %3, double noundef %1) #5
  %5 = fmul double %4, 2.000000e+00
  %6 = tail call double @cq_measure_f64(double noundef %5) #6
  ret double %6
}

declare double @cq_theta_f64(double noundef, double noundef)

declare double @fdim(double noundef, double noundef) #0

declare double @cq_measure_f64(double noundef)

define double @fdim_nested(double noundef %0, double noundef %1) {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #4
  %4 = tail call double @fdim(double noundef %3, double noundef %1) #5
  %5 = tail call double @fdim(double noundef %4, double noundef %1) #5
  %6 = fmul double %5, 2.000000e+00
  %7 = tail call double @cq_measure_f64(double noundef %6) #6
  ret double %7
}

define double @fdim_cond(double noundef %0, double noundef %1, double noundef %2) {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef 5.000000e-01) #4
  %5 = tail call double @fdim(double noundef %4, double noundef %1) #5
  %6 = fcmp oeq double %5, %2
  br i1 %6, label %7, label %8

7:
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #6
  br label %8

8:
  %9 = tail call double @cq_theta_f64(double noundef %4, double noundef -5.000000e-01) #4
  %10 = tail call double @cq_measure_f64(double noundef %9) #6
  ret double %10
}

declare void @cq_phi(double noundef)

define noundef double @__cq_libm_fdim(double noundef %0, double noundef %1) #1 {
  %3 = tail call i32 @__cq_libm_isnan(double noundef %0) #7
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %12

5:
  %6 = tail call i32 @__cq_libm_isnan(double noundef %1) #7
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %8, label %12

8:
  %9 = fcmp ogt double %0, %1
  %10 = fsub double %0, %1
  %11 = select i1 %9, double %10, double 0.000000e+00
  br label %12

12:
  %13 = phi double [ %11, %8 ], [ %0, %2 ], [ %1, %5 ]
  ret double %13
}

define hidden range(i32 0, 2) i32 @__cq_libm_isnan(double noundef %0) #2 {
  %2 = bitcast double %0 to i64
  %3 = and i64 %2, 9218868437227405312
  %4 = icmp eq i64 %3, 9218868437227405312
  %5 = and i64 %2, 4503599627370495
  %6 = icmp ne i64 %5, 0
  %7 = and i1 %4, %6
  %8 = zext i1 %7 to i32
  ret i32 %8
}

attributes #0 = { mustprogress nofree nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind ssp uwtable "no-builtins" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "no-builtins" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind willreturn memory(none) }
attributes #6 = { nounwind }
attributes #7 = { nobuiltin nounwind "no-builtins" }
