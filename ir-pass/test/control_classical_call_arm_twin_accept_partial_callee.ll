; control_classical_call_arm_twin_accept_partial_callee.ll — ACCEPT (batch 053, bd
; dm7f.30; was control_classical_call_arm_reject_partial_callee.ll, a TOTALITY reject
; since bd wve8).
; The callee body IS VISIBLE, IS a `memory(none) nounwind willreturn` definition, and
; is PARTIAL: `sdiv i32 100, %x` is immediate UB at `%x == 0` (and at `INT_MIN / -1`).
;
; THE wve8 LESSON STILL HOLDS AND THIS ROW STILL PINS IT: purity is not totality.
; `mayHaveSideEffects()` is `mayWriteToMemory() || mayThrow() || !willReturn()`, and a
; trapping division is none of those; hoisting `@partial_f` ITSELF above the flag
; mint (`Call->moveBefore(BI)` in ClassicalCallArmEmit.cpp) would run it on every
; execution, including the ones the source's quantum guard excluded, and SIGFPE. The
; Direct route still refuses it (`isSpeculatableTotalCallee`: a register divisor
; fails the strict walk), and nothing here hoists the original.
; What changed (batch 053): the Twin route hoists `@partial_f`'s speculation-safe
; twin, whose divisor is GUARDED (TwinTotality.h): `select((x == 0) | (x == -1), 1,
; freeze x)`, the `x == -1` quotient rebuilt as `0 - 100`. The call passes the
; constant 0 (the argument the source shields): the twin divides by 1.
; ANALYTIC (R2): on a basis state where the source runs `partial_f(x)` without UB, x
; is defined and non-zero, the guard selects it (and `0 - 100` is `100 / -1`), so the
; twin returns `partial_f(x)`; this source has no such state for the guard `q > 3`
; under Ry(0), so the twin's value is never merged.
;
; ARM-KILL (kept from the decline): replace ONLY the `sdiv i32 100, %x` with
; `add i32 %x, 100` and the call takes the Direct route (no twin, no guard): the twin
; here is the DIVISION's, not the visible body's, the call's or the diamond's.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @example(
; CHECK:       %r = call i32 @__cq_specsafe_partial_f(i32 0)
; CHECK-NOT:   call i32 @partial_f(
; CHECK:       define internal i32 @__cq_specsafe_partial_f(i32 %x) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TW:[0-9]+]] {
; CHECK-NEXT:    %cq.div.fr = freeze i32 %x
; CHECK-NEXT:    %cq.div.zero = icmp eq i32 %cq.div.fr, 0
; CHECK-NEXT:    %cq.div.m1 = icmp eq i32 %cq.div.fr, -1
; CHECK-NEXT:    %cq.div.bad = or i1 %cq.div.zero, %cq.div.m1
; CHECK-NEXT:    %cq.div.safe = select i1 %cq.div.bad, i32 1, i32 %cq.div.fr
; CHECK-NEXT:    %r = sdiv i32 100, %cq.div.safe
; CHECK-NEXT:    %cq.div.res = select i1 %cq.div.m1, i32 -100, i32 %r
; CHECK-NEXT:    %cq.div.res.fr = freeze i32 %cq.div.res
; CHECK-NEXT:    ret i32 %cq.div.res.fr
; CHECK:       ![[TW]] = !{ptr @partial_f}
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
