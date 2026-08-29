; lowering_mc_late_sub_after.ll — ACCEPT (M-C Increment 7a, bd
; test_C_libtooling-x67f). WAS lowering_reject_live_record_mc_sub_after.ll, a
; LOUD DECLINE at the M-A live-record guard; it is renamed and re-dispositioned
; here because the increment FIXED the program, not because the guard moved.
;
; WHAT IT USED TO PIN (bd memory [mc-cannot-see-mb-discharge-2026-08-29], and
; bd 160a's Rule-13 finding F1f, which turned that memory into these three
; fixtures). `lowerOps` runs BEFORE `uncompute`, so the M-C prior-use fence
; (`ArithLowering::priorUseIsSettled`) could only see a discharge that some
; EARLIER emitter had already inlined. Here the prior readers of the register
; are the DERIVED oracle's own chain templates, whose `_unc` + `cqrt_free` the
; M-B interior partition emits LATER — and, at the moment `lowerOps` Phase 1
; asks, are not even `CallInst`s yet (they are still plain `ashr`/`add`
; opcodes, which arm (e) refuses on sight). So `a -= off` stayed OUT of place,
; minted a fresh rail, and the ORIGINAL register stood as a dead ancestor
; record at the S† `cq_theta`, where the M-A guard declined the whole program
; with a message naming the wrong cause.
;
; WHAT IT PINS NOW. The LATE round (`lowerLateReassignments`, the last stage
; before `uncompute`) re-asks the SAME fence on the fully-lowered module with
; the M-B discharge PLAN in hand. The chain rails are planned for discharge
; right after the region's flag strip — provably before the sub — so arm (d2)
; settles them and the sub converts to the in-place `cqrt_addc_i32(%h, -off)`.
;
; THERE IS NO `cqrt_subc_`, AND THERE MUST NOT BE. `x - c` and `x + (-c)` are
; the same permutation under the runtime's `h := (h + imm) mod 2^W` contract, so
; `sub` emits `cqrt_addc_<W>` with the immediate negated by ordinary CLASSICAL
; IR (`sub i32 0, %off` here, since `off` is an SSA value). The Phase-11 freeze
; surface is untouched (Rule 15).
;
; THE RESULT IS A ONE-RAIL PROGRAM, which is the physics claim: at the ONLY
; `cqrt_ry_i32` after the region, the sole allocated rail is `%h` — the work
; rail, the flag and both chain rails have been freed on the lines above. That
; is what the CHECK-NEXT chain below pins, and it is why the M-A guard now has
; nothing to name.
;
; RED STATE: this file is RED on every plugin built before Increment 7a — there
; it exits non-zero at the guard, so both the `%cq-opt` RUN line and every CHECK
; fail. The siblings are lowering_mc_late_add_sub_around.ll (the `+= off` /
; `-= off` pair around the region) and lowering_mc_late_grover2_offset.ll (two
; full Grover iterations carrying the offset trick). One function per file:
; before the flip the pass stopped at the first loud diagnostic, and keeping the
; split means each shape still fails on its own.
;
; `%off` is a volatile load so nothing folds it away.
;
; SHAPE (`clang -O1` output of):
;     int a = cq_theta(u, 0.5);
;     if (((a * 5) >> 2) == 5) a = cq_phi(a, PI);
;     a -= off;
;     a = cq_theta(a, -0.5);  return cq_measure(a);
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @mc_sub_after(i32 noundef %0, ptr noundef %1) {
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
  %13 = call i32 @cq_theta_si32(i32 noundef %12, double noundef -5.000000e-01)
  %14 = call i32 @cq_measure_si32(i32 noundef %13)
  ret i32 %14
}

; CHECK-LABEL: define i32 @mc_sub_after(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[SH:.*]] = call i32 @cq_template_ashr_i32_hl(i32 %[[H]], i32 2)
; CHECK-NEXT: %[[AD:.*]] = call i32 @cq_template_add_i32(i32 %[[H]], i32 %[[SH]])
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[AD]], i32 5)
; CHECK-NEXT: %[[W:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[W]])
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[W]],
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[W]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[W]])
; the recorded flag strip, then the M-B interior discharge of the whole chain —
; every line of it BEFORE the in-place sub below, which is exactly the fact the
; late round's arm (d2) reads out of the plan.
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[AD]], i32 5)
; CHECK-NEXT: call void @cq_template_add_i32_unc(i32 %[[AD]], i32 %[[H]], i32 %[[SH]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[AD]])
; CHECK-NEXT: call void @cq_template_ashr_i32_hl_unc(i32 %[[SH]], i32 %[[H]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[SH]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the M-C conversion: no fresh rail, and the immediate is negated in classical IR
; CHECK-NEXT: %[[NEG:.*]] = sub i32 0, %3
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[NEG]])
; the S-dagger rotation and the measurement both land on the SAME rail
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
; and the out-of-place lowering is gone entirely — no second data rail is minted
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
