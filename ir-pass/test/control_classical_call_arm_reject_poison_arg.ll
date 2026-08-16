; control_classical_call_arm_reject_poison_arg.ll — TOTALITY reject, the ARGUMENT
; half (bd wve8). Both CALLEE proofs are satisfied here and the region still
; declines, because the UB lives at the CALL rather than inside the function.
;
; `@pf` is impeccable: visible, non-interposable, single-block, `add`-only,
; `memory(none) nounwind willreturn` — it passes `isSpeculatableTotalCallee`
; outright. What is not impeccable is `%p = shl i32 1, %n`, which is POISON for
; `%n >= 32`, passed to a parameter attributed `noundef`. Passing poison to a
; `noundef` parameter is IMMEDIATE UB, and the 6.5 hoist manufactures it out of
; nothing: the source evaluates the call only under a quantum guard, so on a
; program where that guard has zero amplitude there is no UB at all until the call
; is made unconditional.
;
; THIS SHAPE REACHED THE ACCEPT PATH AFTER THE CALLEE-SIDE FIXES LANDED — it was
; measured at exit 0 with both the `speculatable` disjunct and the strict body walk
; in place, which is why the gate has an argument clause at all. Note the poison is
; computed in the PRED, not the arm: the arm is exactly call + br by
; classification, so the hoist does not move the `shl`; it moves only the CALL,
; and that alone is what turns a defined program into an undefined one.
;
; WHY `noundef` IS THE WHOLE CHECK rather than an enumeration of attributes (the
; bd s6ao discipline): if a parameter is NOT `noundef`, passing it poison is
; simply not UB. `nonnull`/`align`/`dereferenceable` violations yield poison, not
; UB, and the thing that would turn such a pointer into UB is a memory access
; inside the callee — which the strict twin refuses outright.
;
; ARM-KILL: replace `%p = shl i32 1, %n` with `%p = add i32 %n, 1`. `add` without
; nsw/nuw cannot create poison and `%n` is `noundef`, so `%p` is provably defined
; and the SAME module with the SAME `noundef` parameter ACCEPTS. Verified in both
; directions. So the decline is the POISON-CAPABLE ARGUMENT — not the shift, not
; the attribute, and not the call.
;
; NOTE THE POSITION-SENSITIVITY, because it is the trap next door:
; `isGuaranteedNotToBeUndefOrPoison` is what answers this question, and it answers
; it CORRECTLY here (measured: `gnp=0` for the `shl` in the argument position)
; while being CIRCULAR one gate over, at a branch condition inside the callee,
; where it returns 1 for `icmp(shl)` because it also reasons from uses and a `br`
; is UB on poison. Same predicate, opposite usefulness, decided by position. Both
; were measured rather than argued; see the terminator clause in
; PredMuxFlatten.cpp.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; passes every callee-side clause of the totality gate.
define internal i32 @pf(i32 noundef %x) #0 {
  %a = add i32 %x, 1
  ret i32 %a
}

define i32 @example(i32 noundef %u0, i32 noundef %n) {
entry:
  %p = shl i32 1, %n                ; poison for %n >= 32, computed unconditionally
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pf(i32 noundef %p) ; poison -> noundef parameter = immediate UB
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; NOTE, so nobody adds a vacuous assertion here: there is deliberately NO
; `CHECK-NOT` for the emitted stream. On a `DS_Error` the diagnostic handler exits
; before the module is printed, so cq-opt writes ZERO bytes to stdout and a
; CHECK-NOT over this stream can never match under ANY behaviour of the gate.
