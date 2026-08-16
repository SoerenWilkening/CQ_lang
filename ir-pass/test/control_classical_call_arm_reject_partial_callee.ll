; control_classical_call_arm_reject_partial_callee.ll — TOTALITY reject (bd wve8),
; the case that cannot be blamed on opacity: the callee body IS VISIBLE, IS a
; `memory(none) nounwind willreturn` definition, and is still refused because it is
; PARTIAL — `sdiv i32 100, %x` is immediate UB at `%x == 0` (and at
; `INT_MIN / -1`).
;
; WHY THE OLD GATE LET IT THROUGH: `!doesNotAccessMemory() || mayHaveSideEffects()`
; is a scan for which BAD properties are present, and `mayHaveSideEffects()` is
; `mayWriteToMemory() || mayThrow() || !willReturn()`. A trapping division writes
; nothing, throws nothing and returns, so the scan reports a clean callee. The 6.5
; lowering then HOISTS the call above the flag mint (`Call->moveBefore(BI)` in
; ClassicalCallArmEmit.cpp) and it runs on every execution, including the ones the
; source's quantum guard excluded. That is the bd s6ao error one level up: ask
; whether the call is provably SAFE TO SPECULATE, never which hazards you happened
; to enumerate.
;
; The gate now asks the converse question, and `isSpeculatableTotalCallee` answers
; it here at the division: `isSpeculatableDataflow` admits `sdiv`/`udiv`/`srem`/
; `urem` only on a NON-ZERO ConstantInt divisor (with an additional `-1` exclusion
; for the SIGNED forms only — `udiv`/`urem` by -1 are total and ARE admitted), so a
; REGISTER divisor fails the body walk and the arm DECLINES loudly.
;
; ARM-KILL: replace ONLY the `sdiv i32 100, %x` with `add i32 %x, 100`, changing
; nothing else in this file, and it ACCEPTS and lowers (verified in both
; directions). That is the same BODY the committed
; control_classical_call_arm_accept.ll uses, though that file is not otherwise
; identical to this one. So this decline is the DIVISION — not the visible body,
; not the call, and not the diamond.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; VISIBLE, pure, terminating — and PARTIAL. For
; `__attribute__((const)) int recip100(int x) { return 100 / x; }` clang puts a
; superset on the definition (`mustprogress nofree nosync` as well); the CALL SITE
; carries exactly the three below, which is the set the gate reads.
define i32 @partial_f(i32 %x) #0 {
  %r = sdiv i32 100, %x
  ret i32 %r
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @partial_f(i32 0)      ; UB iff evaluated — the source never is
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
; CHECK-NOT over this stream can never match under ANY behaviour of the gate —
; it would read as a second, independent assertion while asserting nothing. The
; decline is fully pinned by `not` (the exit code) plus the message above.
