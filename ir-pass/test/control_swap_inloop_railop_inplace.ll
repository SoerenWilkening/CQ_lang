; control_swap_inloop_railop_inplace.ll — ACCEPT, and the RED-GREEN FIXTURE FOR A
; SILENT MISCOMPILE THE FIRST DRAFT OF bd test_C_libtooling-8h7d.5 SHIPPED.
;
;     q = cq_theta(q, .5); q += off;                 // the PRE-HEADER chain
;     for (...) { if (q == 5) q = cq_phi(q, PI);
;                 q = cq_theta(q, -.5); q += off; q = cq_theta(q, .5); }
;
; VERBATIM `clang -O1` output (`off` is `volatile`, so the offsets survive
; canonicalization and the immediate is a RUNTIME value — Rule 9).
;
; THE DEFECT. `collapseFlattenedLoopRails` RAUWs the loop-carried header phi to
; its ROOT MINT. The root is reached by PEELING through in-place gates, and a
; value self-update (`q += off`, issue dtzb) is one of them — so the peel walks
; STRAIGHT PAST `%3 = add %2, %1` and the collapse RAUWs every in-loop use to the
; PRE-OFFSET handle. Round 1 (`tryCaseA`) compensates by marking each such op into
; `taint.InPlaceRailOps`, which is what makes `lowerOps` emit the IN-PLACE
; `cqrt_addc_i32(h, imm)` rather than the out-of-place `cq_template_add_i32_hl`
; that mints a fresh rail. The first draft of round 2 collapsed WITHOUT marking:
; the add lowered out of place into a rail nothing read, and the whole loop
; computed on `q` where the source says `q + off`.
;
; IT WAS INVISIBLE TO EVERY OTHER GATE. `opt` exit 0, `opt -verify` clean, strict
; stage-2b free-pairing clean (the orphan rail is simply never freed, which Rule 6
; permits), and the golden byte-diff would have been "correct" against a golden
; regenerated from the broken build. The only outward sign was ONE M-A warning
; about a live derived record — i.e. the dead pre-offset handle. This fixture and
; tests/e2e/slice_control_grover_loop_offset.c are what make it loud.
;
; So the two CHECKs below are not decoration: `cqrt_addc_i32` present and
; `cq_template_add_i32_hl` ABSENT is the whole assertion. Delete the
; `InPlaceRailOps` marking from `collapseRailPhisIn` and this goes red.
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. Nothing else moves — the flag
; mint, the strip, the flag free and every downstream gate are unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

@cq_off = global i32 3, align 4

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_phi_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = load volatile i32, ptr @cq_off, align 4
  %3 = add nsw i32 %2, %1
  br label %6
4:                                                ; preds = %12
  %5 = tail call i32 @cq_measure_si32(i32 noundef %17)
  ret i32 %5
6:                                                ; preds = %0, %12
  %7 = phi i32 [ 0, %0 ], [ %18, %12 ]
  %8 = phi i32 [ %3, %0 ], [ %17, %12 ]
  %9 = icmp eq i32 %8, 5
  br i1 %9, label %10, label %12
10:                                               ; preds = %6
  %11 = tail call i32 @cq_phi_si32(i32 noundef 5, double noundef 0x400921FB54442D18)
  br label %12
12:                                               ; preds = %10, %6
  %13 = phi i32 [ %11, %10 ], [ %8, %6 ]
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef -5.000000e-01)
  %15 = load volatile i32, ptr @cq_off, align 4
  %16 = add nsw i32 %15, %14
  %17 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 5.000000e-01)
  %18 = add nuw nsw i32 %7, 1
  %19 = icmp eq i32 %7, 0
  br i1 %19, label %6, label %4
}

; ONE register, and BOTH offsets are IN-PLACE mutations of it — the pre-header one
; and the in-body one:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[O1:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @cq_off
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 %[[O1]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; the rolled body, on the SAME handle throughout:
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double 0x400921FB54442D18)
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK:     %[[O2:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @cq_off
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 %[[O2]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
;
; THE ASSERTION: no out-of-place add anywhere. An orphan `cq_template_add_i32_hl`
; rail here IS the miscompile — the loop would run on the pre-offset register.
; CHECK-NOT: cq_template_add_i32_hl
; The swap route must not come back for this flat phase shape. NOROUTE carries NO
; positive anchor, so its window is the whole module — not a dead trailing span
; (bd memory [filecheck-check-not-window-trap]):
; NOROUTE-NOT: call void @cqrt_cswap
