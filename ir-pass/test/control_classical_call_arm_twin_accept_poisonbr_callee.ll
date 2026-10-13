; control_classical_call_arm_twin_accept_poisonbr_callee.ll — ACCEPT (batch 053, bd
; dm7f.29; was control_classical_call_arm_reject_poisonbr_callee.ll, a TOTALITY reject,
; the TERMINATOR-SKIP case, since bd wve8).
; `%s = shl i32 1, %x` is poison for `%x >= 32`, so `%c` is poison and `br i1 %c` is
; IMMEDIATE UB on exactly those inputs: hoisting `@pf` ITSELF out of the guard would
; execute it on a path the source shielded. The Direct route still refuses it
; (`isSpeculatableTotalCallee` refuses a conditional branch outright).
;
; *** THE MEASURED TRAP THIS ROW RECORDED STILL STANDS. *** Asking
; `isGuaranteedNotToBeUndefOrPoison` on the branch condition answers 1 for `%c`
; (LLVM 19 reasons from USES: a `br` condition is UB on poison, so a well-defined
; program implies `%c` is not poison) while it answers 0 for `%s`: the question
; asked backwards. The twin-mode dataflow (PoisonFlow.cpp) never asks it: it walks
; forward from every parameter possibly poison and treats a branch condition as a
; SINK (`getGuaranteedNonPoisonOps`).
; What changed (batch 053): the Twin route hoists `@pf`'s twin, whose condition is
; FROZEN (`%c.fr`). ANALYTIC (R2): on a basis state where the source runs `pf(k)`
; without UB, `%c` is defined (a branch on poison is UB), so the freeze is the
; identity and the twin takes the source's edge and returns `pf(k)`; elsewhere it
; takes some edge and returns 1 or 2, never merged. The root argument `%k` (no
; `noundef` on `@example`'s parameter) is frozen too (bd 9hea).
;
; ARM-KILL, committed as its own file: control_classical_call_arm_accept_poisonselect_callee.ll
; keeps the SAME poison-capable `shl` and the SAME `icmp` and replaces ONLY the
; conditional branch with a `select`: it lowers by the Direct route, no twin.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @example(
; CHECK:       %k.fr = freeze i32 %k
; CHECK-NEXT:  %r = call i32 @__cq_specsafe_pf(i32 %k.fr)
; CHECK-NOT:   call i32 @pf(
; CHECK:       define internal i32 @__cq_specsafe_pf(i32 noundef %x) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TW:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %s = shl i32 1, %x
; CHECK-NEXT:    %c = icmp eq i32 %s, 7
; CHECK-NEXT:    %c.fr = freeze i1 %c
; CHECK-NEXT:    br i1 %c.fr, label %t, label %f
; CHECK:       t:
; CHECK-NEXT:    ret i32 1
; CHECK:       f:
; CHECK-NEXT:    ret i32 2
; CHECK:       ![[TW]] = !{ptr @pf}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @pf(i32 noundef %x) #0 {
entry:
  %s = shl i32 1, %x            ; poison when %x >= 32
  %c = icmp eq i32 %s, 7        ; poison
  br i1 %c, label %t, label %f  ; IMMEDIATE UB in the original; frozen in the twin
t:
  ret i32 1
f:
  ret i32 2
}

define i32 @example(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pf(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
