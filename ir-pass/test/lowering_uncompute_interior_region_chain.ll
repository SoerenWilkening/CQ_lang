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
; WHY THE `sitofp` ADJOINT MAY READ THE WIRE ACROSS THE REGION — RESTATED FOR
; CONTROL-IN-PLACE (drbq Inc 2a; the paragraph this replaces argued the same
; verdict from the swap route, which this path no longer emits).
; `cq_template_sitofp_i32_to_f64_unc(%[[C]], %[[H]])` recomputes `sitofp` from
; %[[H]]'s COMPUTATIONAL-BASIS LABEL — an `_unc` is a label-only reader — and the
; region's ONLY gate on %[[H]] is now `cqrt_rz_i32_controlled(flag, %[[H]], 3.0)`,
; which is `diag(1, e^{i3})` on the flag-set branch and `I` on the other:
; DIAGONAL either way, so the label is not restored-after-being-moved, it is NEVER
; MOVED. `Uncomputation::preservesBorrowedParent` clause (1b) states exactly that,
; pointwise, for this one gate. It deliberately does NOT restore the wire's PHASE
; — that phase IS the answer the region computed — and by the label-only-reader
; argument that is exactly what makes this legal. (The pre-2a route needed the
; weaker GROUP argument of clause (d2): two `cqrt_cswap`s are the identity on the
; label only when BOTH run. There is no group here to prove.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEH < %t.cqd0.ll
; The route's ABSENCE, anchored at the function header so the window is the whole
; function (a trailing CHECK-NOT scans only past the LAST positive of its prefix).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
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
; the region, CONTROL-IN-PLACE since drbq Inc 2a: the arm is the FALSE successor
; (`fcmp ugt` -> the gate arm is ¬flag), so its gate run is X-bracketed, and the
; Rz lands on the user's own register — no work rail, no route, nothing to free.
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double 3.000000e+00)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
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

; No swap route survives on this path: no |0> work rail, no CSWAP.
; NOROUTE:     define i32 @slice(
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
