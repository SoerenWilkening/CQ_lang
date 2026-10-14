; control_swap_select_chain_fdim.ll — ACCEPT (3c6m.12 L4, chain PIN — no pass
; change): TWO chained tainted-condition selects, the census-exact openlibm
; `fdim(q, 0.25)` qc-mask shape (`clang -O1` body → always-inline →
; `default<O2>`; compound-cond-select-PRD §0). The INNER merge's out-rail feeds
; the OUTER merge as a tainted copy SOURCE — the derived-base mechanics the
; atan2-qq clearance verified (bd `libm-census-multiarg-taint-masks-3c6m48`).
; Each select is an independent `SelectRegion`; no compound condition here.
; This fixture pins the "fp-select chains" half of the 3c6m.12 lever as a
; regression baseline: it lowers TODAY and must keep lowering.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q    = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %uno  = fcmp uno double %q, 0.000000e+00
  %ogt  = fcmp ogt double %q, 2.500000e-01
  %sub  = fadd double %q, -2.500000e-01
  %sel1 = select i1 %ogt, double %sub, double 0.000000e+00
  %sel2 = select i1 %uno, double %q, double %sel1
  %m    = call double @cq_measure_f64(double %sel2)
  ret double %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK:     %[[SUB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(i32 %[[Q]], double -2.500000e-01)
; inner select (%sel1) — flag from the ogt compare, its own out-rail:
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[Q]], double 2.500000e-01)
; CHECK:     %[[OUT1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[F1]], i32 %[[SUB]], i32 %[[OUT1]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[F1]], i32 %[[ZERO:[a-zA-Z0-9_.]+]], i32 %[[OUT1]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; outer select (%sel2) — the INNER OUT-RAIL is its false copy source:
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_uno_f64_hl(i32 %[[Q]], double 0.000000e+00)
; CHECK:     %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[F2]], i32 %[[Q]], i32 %[[OUT2]])
; CHECK:     call void @cqrt_x(i32 %[[F2]])
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[F2]], i32 %[[OUT1]], i32 %[[OUT2]])
; CHECK:     call void @cqrt_x(i32 %[[F2]])
; bd r2j3.32: the first merge rail is the second merge's copy source and has
; no reader after it, so it is reversed there -- its core re-emitted in reverse
; under the SAME flag, its flag strip DEFERRED to after that, then it is freed.
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F1]], i32 %[[ZERO]], i32 %[[OUT1]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F1]], i32 %[[SUB]], i32 %[[OUT1]])
; CHECK-NEXT: call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[F1]], i32 %[[Q]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT1]])
; CHECK:     call void @cq_template_fcmp_uno_f64_hl_unc(i32 %[[F2]], i32 %[[Q]], double 0.000000e+00)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[OUT2]])
; CHECK-NOT: select i1
