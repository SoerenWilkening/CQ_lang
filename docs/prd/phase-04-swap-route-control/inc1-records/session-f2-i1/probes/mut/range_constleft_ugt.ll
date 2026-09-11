; control_inplace_ry_reject_stateprep_range_constleft_ugt.ll — DECLINE (F2, the
; RANGE clause with the LITERAL ON THE LEFT). THIS FILE PINS
; `ICmpInst::getSwappedPredicate` AND NOTHING ELSE IN THE FAMILY DOES.
;
; ⚠ WHY IT EXISTS (round-2 Rule-13 review, lens R1 finding F-R1-5, WEAK-PIN).
; `clang` canonicalizes the constant to the RIGHT, so every one of the family's
; other fixtures is written that way and
; `grep "icmp [a-z]* i[0-9]* [0-9-]" ir-pass/test/control_inplace_ry_*stateprep*.ll`
; returned ZERO hits: deleting the `Rel = ICmpInst::getSwappedPredicate(Rel)`
; line in F2 reddened nothing. It is not dead code — hand-written IR, an
; `-O2`/`-O3` regression run, or any future non-clang producer can hand the pass
; this form, and without the swap F2 would ask the WRONG relation of `H` and go
; silent.
;
; THE ALGEBRA, both ways, so the pin is legible:
;   `icmp ugt i32 1, %t` means `1 > t`, i.e. `t < 1`. `%t = and %q, 1` has range
;   `[0,2)`.
;   WITH the swap (`Rel = ult`):  true edge `[0,1) = {0}`; FALSE edge
;   `uge 1` ∩ `[0,2)` = `{1}` — the SEED. Decline.
;   WITHOUT it (`Rel` left as `ugt`): true edge `[2,0)` ∩ `[0,2)` = EMPTY; false
;   edge `ule 1` ∩ `[0,2)` = `[0,2)`, not a singleton. NO decline — the module
;   ACCEPTS and the condition rail `%t` is never rotated while the source
;   measures it. Measured both ways.
;
; ITS ACCEPT CONTROL is `control_inplace_ry_stateprep_range_constleft_accept.ll`
; (same shape, `icmp ugt i32 6, %t` over `and %q, 6`, seed 0 — the swapped
; relation pins nothing there), so the swap is pinned as a DISCRIMINATOR and not
; as a blanket over-decline. `..._range_constleft_eq.ll` pins the OTHER half of
; the same code — the position-free `{K, H}` selection — which an `eq` cannot
; discriminate because `getSwappedPredicate(eq) == eq`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t = and i32 %q, 2
  %c = icmp ugt i32 1, %t
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 1, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 1, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s  = add i32 %mr, %mt
  ret i32 %s
}
