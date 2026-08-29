; lowering_mc_late_fallback_reader_after.ll — FALLBACK (M-C Increment 7a, bd
; test_C_libtooling-x67f). The site stays OUT OF PLACE, which is not a decline:
; `cq_template_sub_i32_hl` is a lowering this compiler emits correctly, and the
; whole M-C fence is written so that failing it costs a kept ancestor rail and
; nothing else (Rule 17 — the decline belongs to inputs outside the target
; shape, not to a shape we lower).
;
; WHAT IT PINS: THE POSITION HALF OF ARM (d2). The late round admits a prior
; producer whose rail the M-B interior partition has PLANNED to discharge — but
; only when that discharge is `provablyBefore` the site. Here the derived
; condition's chain rail is read by TWO recorded flag strips, and the SECOND
; region sits AFTER the subtraction. The interior anchor is the nearest common
; post-dominator of the point right after every consumer, so it lands after the
; second strip, i.e. after the site. The chain's `_unc`s therefore run with the
; register ALREADY relabelled if the sub had been converted, and the adjoint of
; `add(q, q>>2)` would recompute from the wrong basis — a dirty rail and a
; `cqrt_free` that is a hidden measurement (Rules 6/8), verify-clean and
; invisible to the golden byte-diff. The plan HAS an entry for these gates; it
; is the placement that refuses.
;
; CONTRAST WITH ITS SIBLINGS, because the three refuse at three different steps:
;   * this file — the gate IS planned, the `At` is not before the site;
;   * _fallback_measured_chain.ll — no plan entry at all (the rail is measured,
;     so the interior partition never owns it);
;   * _fallback_terminal_dag.ll — planned, well placed, and WITHHELD because the
;     dead-terminal spine could reach the gate.
;
; NO RED STATE EXISTS on any earlier plugin: before Increment 7a nothing
; converted late at all, so this file is green on every one of them for a
; different reason. MEASURED MUTATION instead (bd memory
; [rule12-pins-without-a-red-state-2026-08-29]): dropping the position test in
; `ArithLowering::priorUseIsSettled` arm (d2) —
;     if (It != Plan->GateAt.end() && provablyBefore(It->second, bo, DT))
;   → if (It != Plan->GateAt.end())
; converts the sub here and reddens this file, while
; _fallback_measured_chain.ll and _fallback_terminal_dag.ll stay green (they
; refuse at the other two steps).
;
; `%off` is a volatile load so nothing folds it away. Both regions are ordinary
; flat diamonds; the sequential pair lowers since bd hcrg.
;
; SHAPE (`clang -O1` output of, with `z = t * 3; if (z == 9)` const-folded by
; clang into the `t == 3` spelling below):
;     int a = cq_theta(u, 0.5);
;     int t = (a >> 2) + a;
;     if (t == 5) a = cq_phi(a, PI);
;     a -= off;
;     if (t == 3) a = cq_phi(a, 1.5);
;     return cq_measure(a);
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOCONV < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @late_reader_after(i32 noundef %0, ptr noundef %1) {
  %3 = load volatile i32, ptr %1, align 4
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = ashr i32 %4, 2
  %6 = add nsw i32 %5, %4
  %7 = icmp eq i32 %6, 5
  br i1 %7, label %8, label %10
8:
  %9 = call i32 @cq_phi_si32(i32 noundef %4, double noundef 0x400921FB54442D18)
  br label %10
10:
  %11 = phi i32 [ %9, %8 ], [ %4, %2 ]
  %12 = sub nsw i32 %11, %3
  %13 = icmp eq i32 %6, 3
  br i1 %13, label %14, label %16
14:
  %15 = call i32 @cq_phi_si32(i32 noundef %12, double noundef 1.500000e+00)
  br label %16
16:
  %17 = phi i32 [ %15, %14 ], [ %12, %10 ]
  %18 = call i32 @cq_measure_si32(i32 noundef %17)
  ret i32 %18
}

; CHECK-LABEL: define i32 @late_reader_after(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[SH:.*]] = call i32 @cq_template_ashr_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[AD:.*]] = call i32 @cq_template_add_i32(i32 %[[H]], i32 %[[SH]])
; region 1's strip fires here, but the chain is NOT discharged after it — the
; component's anchor has been dragged past the second region below.
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %{{.*}}, i32 %[[AD]], i32 5)
; CHECK-NEXT: call void @cqrt_free(
; THE SITE, out of place: a fresh rail carries `a - off` and the register stays.
; CHECK-NEXT: %[[SUB:.*]] = call i32 @cq_template_sub_i32_hl(i32 %[[H]], i32 %3)
; region 2 routes THAT rail, and reads the chain rail again for its own flag.
; CHECK-NEXT: %[[F2:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[AD]], i32 3)
; CHECK:      call void @cqrt_cswap(i32 %[[F2]], i32 %[[SUB]], i32 %{{.*}})
; only now does the chain discharge — after the site, which is exactly why the
; site could not be converted.
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[AD]], i32 3)
; CHECK-NEXT: call void @cq_template_add_i32_unc(i32 %[[AD]], i32 %[[H]], i32 %[[SH]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[AD]])
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[SH]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[SH]])

; NO in-place gate anywhere in the function — the fence refused, and the whole
; point of the fixture is that the refusal is total, not partial.
; NOCONV-NOT: cqrt_addc_i32
; NOCONV-NOT: cqrt_xorc_i32
