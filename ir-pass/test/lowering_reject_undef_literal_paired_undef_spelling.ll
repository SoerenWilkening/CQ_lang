; lowering_reject_undef_literal_paired_undef_spelling.ll — DECLINE (bd xy9n).
; ARM: `declineUnpairedUndefLiterals` — the SPELLING row.
;
; The `undef` spelling of lowering_reject_undef_literal_paired_dead_chain.ll,
; which is the `poison` one. Both are covered by ONE `isa<UndefValue>` because
; `PoisonValue` derives from `UndefValue` — this fixture is what pins that, so a
; future rewrite that reaches for `isa<PoisonValue>` (the natural-looking
; narrowing) goes red here instead of silently re-opening half the defect.
;
; `undef` is the spelling `clang -O1` and `mem2reg` actually emit — the one real
; occurrence in the whole measured corpus (`slice_libm_ld80_nexttoward`) is an
; `undef`, not a `poison`, so this row carries the reachable spelling and the
; other one carries the adversarial spelling.
;
; RED-GREEN: measured ACCEPT (`opt` exit 0) on the pre-change plugin.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: undef/poison literal reaches two emitted gate operands

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %d = add i32 %q, undef
  ret void
}
