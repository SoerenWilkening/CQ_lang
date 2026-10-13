; control_predmux_accept_switch_fp_merge_const.ll — ACCEPT (bd test_C_libtooling-dm7f.17).
; Was control_swap_reject_switch_fpdata.ll, a DECLINE (G4 FP-fence: "fp data merge").
; The owner ruled R3: an fp merge value may carry quantum data; only an ANGLE use
; stays loud. PredMux witness W8 now lowers this constant fp switch merge as a select
; chain. Semantic evidence, reviewed by trace reasoning 2026-10-08 before flipping
; (R10): out = q==0 ? 1.0 : 2.0; g = (q!=0 & q!=1) by Toffoli; out4 = g ? 0.0 : out;
; so out4 = {0.0 default, 1.0 at q==0, 2.0 at q==1}, the source's phi. Stage 2b on
; this output: 4 frees verified, 0 violations. The q-dependent `out` rail is left
; allocated, never freed dirty (R5); a later non-diagonal gate on q is fenced loudly
; ("condition predates a non-diagonal gate", R11 round 3 probe).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.ll
; CHECK-LABEL: define i32 @example(
; CHECK:       %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 0)
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT:  %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 1.000000e+00)
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[C]], i32 %[[S1]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[C]])
; CHECK-NEXT:  %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 2.000000e+00)
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[C]], i32 %[[S2]], i32 %[[OUT]])
; CHECK:       %[[NE0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT:  %[[NE1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT:  %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_toffoli(i32 %[[NE0]], i32 %[[NE1]], i32 %[[G]])
; CHECK-NEXT:  %[[OUT4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT:  %[[S0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[G]], i32 %[[S0]], i32 %[[OUT4]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[G]], i32 %[[OUT]], i32 %[[OUT4]])
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f64_to_i32(i32 %[[OUT4]])
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 %[[R]])
; The first merge rail is never freed: it holds q-dependent garbage (R5), and a free
; would be a hidden measurement of q. ONE positive anchor (its mint, the first
; f64 alloc, which CHECK pins right after the icmp_eq), so the window runs to the end
; of input and tools/fixture_guard_liveness.py can attack it (2026-10-13: the former
; icmp/NEXT/ret spelling bound no handle on its first anchor and had two anchors, so
; the liveness gate could not check it — failing since c574fc04, unmeasured).
; NOFREE-LABEL: define i32 @example(
; NOFREE:       %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; NOFREE-NOT:   call void @cqrt_free(i32 %[[OUT]])
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
