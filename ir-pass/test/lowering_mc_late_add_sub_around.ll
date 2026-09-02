; lowering_mc_late_add_sub_around.ll — ACCEPT (M-C Increment 7a, bd
; test_C_libtooling-x67f). WAS lowering_reject_live_record_mc_add_sub_around.ll,
; a LOUD DECLINE at the M-A live-record guard; renamed and re-dispositioned
; because the increment fixed the PROGRAM, not because the guard moved.
;
; THE SHAPE THIS ONE ADDS over its sibling lowering_mc_late_sub_after.ll: the
; register carries the offset trick on BOTH sides of the region — `a += off`
; before it and `a -= off` after — so the file pins that the two M-C rounds
; compose. THE `+=` CONVERTS IN `lowerOps` PHASE 1, exactly as it always did:
; at that point the only prior user of the source wire is its own `cqrt_ry`,
; which arm (c) settles. It is the `-=` that Phase 1 could not decide, and for a
; reason that has nothing to do with physics — see the sibling's header for the
; pipeline-order account.
;
; So the CHECK chain below is also the statement that the late round is
; ADDITIVE: it takes only the site Phase 1 left behind, and the earlier `addc`
; is byte-identical to what shipped before this increment.
;
; NOTE WHAT THE TWO IMMEDIATES LOOK LIKE, because they are not symmetric. The
; `+=` passes `%3` straight through; the `-=` emits `cqrt_addc_<W>` with the
; immediate NEGATED in ordinary classical IR (`sub i32 0, %3`) — there is no
; `cqrt_subc_` and the Phase-11 freeze surface is untouched (Rule 15). That also
; means `free_pairing_check.py` cannot pair the two by `is_negation` (it relates
; constants, not SSA names) — harmless here because `%h` is MEASURED and so is
; never freed, which is the case the stage-2b docstring already covers.
;
; RED STATE: RED on every plugin built before Increment 7a (it exits non-zero at
; the M-A guard there, so the RUN line itself fails).
;
; `%off` is a volatile load so nothing folds it away.
;
; SHAPE (`clang -O1` output of):
;     int a = cq_theta(u, 0.5);
;     a += off;
;     if (((a * 5) >> 2) == 5) a = cq_phi(a, PI);
;     a -= off;
;     a = cq_theta(a, -0.5);  return cq_measure(a);
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. Nothing else moves — the flag
; mint, the strip, the flag free and every downstream gate are unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @mc_add_before_sub_after(i32 noundef %0, ptr noundef %1) {
  %3 = load volatile i32, ptr %1, align 4
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = add nsw i32 %4, %3
  %6 = ashr i32 %5, 2
  %7 = add nsw i32 %6, %5
  %8 = icmp eq i32 %7, 5
  br i1 %8, label %9, label %11
9:
  %10 = call i32 @cq_phi_si32(i32 noundef %5, double noundef 0x400921FB54442D18)
  br label %11
11:
  %12 = phi i32 [ %10, %9 ], [ %5, %2 ]
  %13 = sub nsw i32 %12, %3
  %14 = call i32 @cq_theta_si32(i32 noundef %13, double noundef -5.000000e-01)
  %15 = call i32 @cq_measure_si32(i32 noundef %14)
  ret i32 %15
}

; CHECK-LABEL: define i32 @mc_add_before_sub_after(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; the Phase-1 conversion (unchanged by this increment)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %3)
; CHECK-NEXT: %[[SH:.*]] = call i32 @cq_template_ashr_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[AD:.*]] = call i32 @cq_template_add_i32(i32 %[[H]], i32 %[[SH]])
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[AD]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[AD]], i32 5)
; CHECK-NEXT: call void @cq_template_add_i32_unc(i32 %[[AD]], i32 %[[H]], i32 %[[SH]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[AD]])
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[SH]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[SH]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the LATE conversion — the site Phase 1 could not decide
; CHECK-NEXT: %[[NEG:.*]] = sub i32 0, %3
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[NEG]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
; ONE RAIL: no data template rail survives the region, and none is minted for
; the subtraction.
; CHECK-NOT: cq_template_sub_i32_hl

; THE M-A GUARD IS SILENT ON THIS PROGRAM, and since owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, M-A Increment 7b) that has to be CHECKED rather than
; inferred. This file's physics claim is that the conversion leaves the guard
; NOTHING TO NAME — which, while the guard was a `DS_Error`, the RUN line's own
; exit code pinned. It now emits a `DS_Warning` and `opt` exits ZERO either way,
; so a future regression in the M-A walk would print a warning on this very
; program and the file would stay green: the CHECK-NEXT chain pins the emitted
; STREAM, and the M-A analysis is keyed on emitter-recorded sets no stream line
; shows. `SILENT` reads the pass's stderr and is the pin that replaces the exit
; code (Increment 7 Rule-13 round, finding F3; same spelling as the 28 accept
; fixtures 7b re-pinned).
; SILENT-NOT: non-diagonal gate over a live derived record
; The swap route must not come back for this flat phase shape. NOROUTE carries NO
; positive anchor, so its window is the whole module — not a dead trailing span
; (bd memory [filecheck-check-not-window-trap]):
; NOROUTE-NOT: call void @cqrt_cswap
