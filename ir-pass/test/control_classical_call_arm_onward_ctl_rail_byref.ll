; control_classical_call_arm_onward_ctl_rail_byref.ll — yn71 Rule-13 ROBUSTNESS pin: a
; round-1 classical-call arm rail `%out` feeds an ONWARD tainted-control classical-call
; arm (`if (%out>7) z=g(b)`) whose NEW merge rail `%out2` then feeds a by-ref math call
; (`frexp((double)%out2, &e)`). The onward ccarm is emitted by yn71's
; `detectAndLowerOnwardControl` fixpoint (building `%out2` AFTER the step-2
; `lowerByRefMath` fixpoint already ran), so the `frexp` reads a ROUND-2-tainted value
; the by-ref lowering never saw.
;
; THE BUG THIS PINS (found by the yn71 Rule-13 adversarial sweep, fixed by folding
; `lowerByRefMath` INTO the onward-control fixpoint): without the re-run, the raw
; `frexp(double, ptr)` survived — `declineTaintEscapes`'s by-ref carve
; (`isByRefMathCall → continue`, assuming `lowerByRefMath` already owned it) waved it
; through, then `lowerOps` lowered its `sitofp` arg to an i32 handle, leaving
; `frexp(i32 %handle, ptr)` against `double @frexp(double, ptr)` — a type-mismatched
; BROKEN MODULE (LLVM verifier abort). The fix re-runs `lowerByRefMath` after the
; control emit (the diamond is already flattened, so the cell is straight-line — the
; 0vvq Inc 1 enabler), lowering the by-ref to `@cq_byref_*`/`cq_template_frexp`
; markers BYTE-IDENTICAL to a round-1-rail by-ref, or loud-declining an off-pattern
; cell — never a raw survivor. (This exact shape is not clang-`-O1`-emittable; it is a
; robustness pin, Rule 10.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @f(i32) #0
declare i32 @g(i32) #0
declare double @frexp(double, ptr)
define i32 @example(i32 %u0, i32 %a, i32 %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]          ; round-1 ccarm merge = %out
  %c2 = icmp sgt i32 %y, 7                            ; tainted only AFTER the re-seed
  br i1 %c2, label %arm2, label %merge2              ; ONWARD ccarm on %out
arm2:
  %r2 = call i32 @g(i32 %b)
  br label %merge2
merge2:
  %z = phi i32 [ %r2, %arm2 ], [ 5, %merge ]         ; onward ccarm merge = %out2 (round-2 rail)
  %ecell = alloca i32
  %d = sitofp i32 %z to double
  %fr = call double @frexp(double %d, ptr %ecell)    ; by-ref math on the round-2 rail
  %ev = load i32, ptr %ecell, align 4
  ret i32 %ev
}
attributes #0 = { nounwind willreturn memory(none) }

; The two cascaded ccarms build %out then %out2 (controlled copies), and the by-ref
; frexp on %out2 lowers to its reversible markers — NO raw frexp(i32, ptr) survives:
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(
; CHECK:     call i32 @cq_template_frexp_f64(i32 %[[CAST]])
; CHECK:     call i32 @cq_template_frexpexp_f64_to_i32(i32 %[[CAST]])
; CHECK-NOT: call double @frexp(double
