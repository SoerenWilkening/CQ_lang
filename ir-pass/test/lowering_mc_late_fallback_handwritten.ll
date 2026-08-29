; lowering_mc_late_fallback_handwritten.ll — FALLBACK (M-C Increment 7a, bd
; test_C_libtooling-x67f). The site stays OUT OF PLACE; that is the existing
; lowering, not a decline (see _fallback_reader_after.ll's header).
;
; WHAT IT PINS: THE PROVENANCE FENCE. The late round recognizes an out-of-place
; M-C site by REBUILDING the symbol from `TemplateName::dataName` — the one
; builder that mints it — and by reading the site's LOGICAL ABI width out of
; `TaintSet::HandleWidth`. That second half is not a convenience: a lowered
; handle is `i32` at EVERY width (Rule 15), so the call's types cannot tell an
; i8 site from an i64 one, and `rewriteBinary`'s `promote` is the only thing
; that ever records which it was.
;
; The consequence is that ONLY a site THIS RUN lowered is eligible. The
; `cq_template_add_i32_hl` below was written by hand into an already-lowered
; module: it has no `HandleWidth` record, so `lateReassignShape` refuses it and
; the round leaves it exactly where it stands — even though its operand shape,
; its width and its user set would all pass the fence.
;
; THAT IS DELIBERATE, AND IT IS THE PRIME DIRECTIVE'S DIRECTION. The late round
; exists to RE-DECIDE a decision `lowerOps` took minutes earlier on IR whose
; shape it had just proved. Hand-written or externally-produced IR carries no
; such proof: nothing here knows that `%5`'s second operand is classical at the
; logical width rather than a rail handle laundered to `i32` (G4's whole
; subject), and guessing "i32" from the result type would be exactly the
; width-blind read Rule 15 warns about. Adopting it would also silently widen
; the round to any module a future front end hands us.
;
; NO RED STATE EXISTS on any earlier plugin. MEASURED MUTATION instead (bd
; memory [rule12-pins-without-a-red-state-2026-08-29]): giving
; `ArithLowering::lateReassignShape` a fallback width when the side table is
; empty —
;     StringRef Wl = taint.HandleWidth.lookup(C);
;     if (Wl.empty()) return false;
;   → StringRef Wl = taint.HandleWidth.lookup(C);
;     if (Wl.empty()) Wl = "i32";
; converts the call here and reddens this file. It leaves every other fixture in
; the family green, because they all go through the real lowering and so all
; have the record.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)

define i32 @handwritten_template(i32 noundef %0, ptr noundef %1) {
  %3 = load volatile i32, ptr %1, align 4
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 7)
  %6 = call i32 @cq_measure_si32(i32 noundef %5)
  ret i32 %6
}

; CHECK-LABEL: define i32 @handwritten_template(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; the hand-written template call is left exactly as it stands
; CHECK-NEXT: %[[T:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 7)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[T]])
; CHECK-NOT: cqrt_addc_i32
