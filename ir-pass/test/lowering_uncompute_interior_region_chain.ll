; lowering_uncompute_interior_region_chain.ll — ACCEPT, and bd
; test_C_libtooling-6uqc's P0 CLOSED (M-B Increment 6, clause (d2); renamed from
; lowering_uncompute_interior_region_partial.ll, which pinned the seam).
;
;     a = cq_theta(a, 0.5);
;     if (sqrt(a + 3.0) <= 5.0) { a = cq_phi(a, 3.0); }
;     return cq_measure(a);
;
; THE DEFECT THIS FILE USED TO PIN. A region whose condition is DERIVED computes
; its compare operand through a chain of template rails — here
; `cq_template_sitofp_i32_to_f64`, `cq_template_fadd_f64_hl`,
; `cq_template_sqrt_f64`. `SwapRouteEmit` strips only the FLAG, so at HEAD
; (c36934a) all three stayed allocated and entangled with the wire forever;
; Increment 5 discharged the first two BEFORE the region and had to leave the
; third, because its second user is the flag strip — a `cq_template_*_unc`, which
; `isTemplateProducer` refuses. Refusing it was CORRECT: discharging at the
; anchor its forward consumers imply would free the rail before the strip
; recomputes the flag from it.
;
; CLAUSE (d2) — the emitter-recorded strip. `SwapRouteEmit`'s PHASE path records
; its strip in `TaintSet::DischargedFlagGates`, `isInteriorConsumer` admits a
; RECORDED strip as a READ of the rails in its shifted handle slots, and the
; interior partition's `dagInsertPoint` then lands right after that strip. The
; whole chain is uncomputed there, LIFO, and freed. THE ORDER BELOW IS THE PROOF:
; the strip runs FIRST (it still reads the live `sqrt` rail), then the three
; adjoints, then the flag free.
;
; WHY THE `sitofp` ADJOINT MAY READ THE WIRE AFTER THE ROUTE. `cq_template_
; sitofp_i32_to_f64_unc(%[[C]], %[[H]])` recomputes `sitofp` from `%[[H]]`'s
; COMPUTATIONAL-BASIS LABEL — an `_unc` is a label-only reader — and the region's
; two `cqrt_cswap(flag, %[[H]], rail)` calls are the SAME call twice under the
; SAME flag, so as a GROUP they are the identity on that label (the join is the
; adjoint of the split). The arm's `Rz` is diagonal and lands on the work RAIL.
; The pair deliberately does NOT restore the wire's PHASE — that phase IS the
; answer the region computed — and by the label-only-reader argument that is
; exactly what makes this legal. Clause (d2) admits the pair as a UNIT, recorded
; at the emitter (`TaintSet::RestoringRoutes`), never re-inferred by scanning for
; two cswaps.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @llvm.sqrt.f64(double)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = sitofp i32 %q to double
  %a  = fadd double %c, 3.000000e+00
  %s  = call double @llvm.sqrt.f64(double %a)
  %gt = fcmp ugt double %s, 5.000000e+00
  br i1 %gt, label %merge, label %arm

arm:
  %qz = call i32 @cq_phi_si32(i32 %q, double 3.000000e+00)
  br label %merge

merge:
  %p = phi i32 [ %qz, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; CHECK-LABEL: define i32 @slice(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[C:.*]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %[[H]])
; CHECK-NEXT: %[[A:.*]] = call i32 @cq_template_fadd_f64_hl(i32 %[[C]], double 3.000000e+00)
; CHECK-NEXT: %[[S:.*]] = call i32 @cq_template_sqrt_f64(i32 %[[A]])
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_fcmp_ugt_f64_hl(i32 %[[S]], double 5.000000e+00)
; the region: work rail, X-bracketed cswap route, arm Rz, route back, rail free
; CHECK-NEXT: %[[R:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[R]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[R]], double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[R]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; the flag strip STILL READS the sqrt rail, and runs BEFORE the discharge:
; CHECK-NEXT: call void @cq_template_fcmp_ugt_f64_hl_unc(i32 %[[F]], i32 %[[S]], double 5.000000e+00)
; …and the whole condition chain is uncomputed here, LIFO, and freed:
; CHECK-NEXT: call void @cq_template_sqrt_f64_unc(i32 %[[S]], i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[S]])
; CHECK-NEXT: call void @cq_template_fadd_f64_hl_unc(i32 %[[A]], i32 %[[C]], double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[C]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; The source wire is a BORROWED parent — it carries the superposition `cqrt_ry`
; minted, so no adjoint returns it to |0> and it is correctly left allocated:
; NOFREEH:     %[[H2:.*]] = call i32 @cqrt_alloc_i32(
; NOFREEH-NOT: call void @cqrt_free(i32 %[[H2]])
