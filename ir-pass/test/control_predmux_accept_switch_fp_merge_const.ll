; control_predmux_accept_switch_fp_merge_const.ll — ACCEPT (bd test_C_libtooling-dm7f.17).
; Was control_swap_reject_switch_fpdata.ll, a DECLINE (G4 FP-fence: "fp data merge").
; The owner ruled R3: an fp merge value may carry quantum data; only an ANGLE use
; stays loud. PredMux witness W8 now lowers this constant fp switch merge as a select
; chain. Semantic evidence, reviewed by trace reasoning 2026-10-08 before flipping
; (R10): out = q==0 ? 1.0 : 2.0; g = (q!=0 & q!=1) by Toffoli; out4 = g ? 0.0 : out;
; so out4 = {0.0 default, 1.0 at q==0, 2.0 at q==1}, the source's phi. Stage 2b on
; the pre-r2j3.32 output: 4 frees verified, 0 violations (measured 2026-10-15 on
; this output: 6 verified, 0 violations, 0 unproven). Since bd r2j3.32 BOTH merge rails
; are reversed after their last reader and freed at |0> (core re-emitted in
; reverse under the still-live flag, the flag strip deferred past it): `out4`
; after the fptosi in the merge block (the straight-line successor), then `out`,
; which `out4`'s reversal reads as a copy source (LIFO). A later non-diagonal
; gate on q is fenced loudly ("condition predates a non-diagonal gate", R11
; round 3 probe).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(
; CHECK:       %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 0)
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT:  call void @cqrt_xorc_f64_controlled(i32 %[[C]], i32 %[[OUT]], double 1.000000e+00)
; CHECK-NEXT:  call void @cqrt_x(i32 %[[C]])
; CHECK-NEXT:  call void @cqrt_xorc_f64_controlled(i32 %[[C]], i32 %[[OUT]], double 2.000000e+00)
; CHECK:       %[[NE0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT:  %[[NE1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT:  %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_toffoli(i32 %[[NE0]], i32 %[[NE1]], i32 %[[G]])
; CHECK-NEXT:  %[[OUT4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT:  call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[G]], i32 %[[OUT]], i32 %[[OUT4]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[G]])
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f64_to_i32(i32 %[[OUT4]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[G]], i32 %[[OUT]], i32 %[[OUT4]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_toffoli(i32 %[[NE0]], i32 %[[NE1]], i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT:  call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[NE1]], i32 %[[H]], i32 1)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[NE1]])
; CHECK-NEXT:  call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[NE0]], i32 %[[H]], i32 0)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[NE0]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[OUT4]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[C]])
; CHECK-NEXT:  call void @cqrt_xorc_f64_controlled(i32 %[[C]], i32 %[[OUT]], double 2.000000e+00)
; CHECK-NEXT:  call void @cqrt_x(i32 %[[C]])
; CHECK-NEXT:  call void @cqrt_xorc_f64_controlled(i32 %[[C]], i32 %[[OUT]], double 1.000000e+00)
; CHECK-NEXT:  call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[C]], i32 %[[H]], i32 0)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 %[[R]])
; (Until bd r2j3.32 a NOFREE guard here pinned the first rail, then `out4`, as
; never freed; both are now reversed and freed — pinned by the stream above.)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %dm = phi double [ 0.000000e+00, %entry ], [ 1.000000e+00, %a0 ], [ 2.000000e+00, %a1 ]
  %r = fptosi double %dm to i32
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
