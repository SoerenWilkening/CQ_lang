; control_predmux_reject_selectform_shift_wide_amount.ll — DECLINE
; (bd 3c6m.14.2). ARM: `definedOpAfterFlagDrop`'s shift-amount range check,
; spelled `APInt::ult` rather than `getZExtValue() <`.
;
; FOUND BY THE RULE-13 ROUND, and it is a Release-build-only defect — the kind a
; `+Asserts` developer build hides. `ConstantInt::getZExtValue()` asserts that the
; value fits in 64 bits; in the SHIPPED Release plugin that assert is compiled out
; and it returns the LOW WORD. So for an `i128` shift by `1 << 100` — whose low
; word is 0 — the old expression computed `0 < 128` and ADMITTED the shift as if
; the amount were zero, while the same shift by 200 correctly declined. Measured
; on the shipped plugin, both spellings, before the fix:
;
;   shl i128 %w, 200            -> decline   (gate=E6-condtree)
;   shl i128 %w, 1<<100         -> ACCEPT    <-- the low word is 0
;
; A shift amount >= the bit width is INHERENT poison with no flag to drop, which
; is the whole reason this arm exists (see
; lowering_predmux_leave_selectform_poisoncone.ll for the runtime-amount twin).
; Admitting one because its low 64 bits happen to be small is the same silent
; miscompile with a narrower trigger.
;
; REACH NOTE, so this fixture is not over-claimed: an amount with >64 active bits
; requires a type wider than 64 bits, so the admitted class was `i65`+ shifts by
; a constant whose low word is < the width. `i128` is a template width the pass
; ships (`isTemplateWidthType`), so the shape is inside the accept surface, not
; outside it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %w = zext i32 %q to i128
  ; 2^100: 101 active bits, low 64 bits all zero. getZExtValue() returns 0.
  %sh = shl i128 %w, 1267650600228229401496703205376
  %t = trunc i128 %sh to i32
  %b = icmp sgt i32 %t, 0
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; DBG: leave @probe entry=entry merge=merge gate=E6-condtree
