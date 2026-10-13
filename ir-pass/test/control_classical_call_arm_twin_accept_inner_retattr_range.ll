; control_classical_call_arm_twin_accept_inner_retattr_range.ll — ACCEPT (bd dm7f.21).
; FLIPPED from control_classical_call_arm_reject_inner_retattr_range.ll (bd bwfp R11
; round 3 F1(a), a DECLINE) by the owner ruling of 2026-10-08 (option a).
; A poison SOURCE that is a return attribute, not an instruction. `@ga` returns its
; argument under `range(i32 0, 5)` WITHOUT `noundef`: for `%x >= 5` the call yields
; poison. `@pa` forwards that result to its own `noundef` return, so `pa(50)` executes
; `ret noundef poison`: immediate UB, which hoisting `@pa` itself would run on basis
; states the guard `q > 3` excluded (all of them, Ry(0)). The hoist now calls `@pa`'s
; speculation-safe twin, whose `ret` is frozen; `@ga` needs no twin (its poison is
; not UB inside it). The dataflow still counts the unproven `range` as a source.
; ANALYTIC (R2): for `%k` in [0, 5) nothing is poison, the `freeze` is the identity
; and the twin returns `pa(%k)`; otherwise the source's own call is UB under a true
; guard, and the twin's value is never merged under a false one. Neighbour: a
; `returned` the body breaks, a decline until batch 053 dropped it in the twin
; (control_classical_call_arm_twin_accept_false_returned.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_specsafe_pa(i32 %k)
; CHECK:       call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       define internal noundef i32 @__cq_specsafe_pa(i32 noundef %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %r = call i32 @ga(i32 %x)
; CHECK-NEXT:    %r.fr = freeze i32 %r
; CHECK-NEXT:    ret i32 %r.fr

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal range(i32 0, 5) i32 @ga(i32 %x) #0 {
entry:
  ret i32 %x
}

define internal noundef i32 @pa(i32 noundef %x) #0 {
entry:
  %r = call i32 @ga(i32 %x)
  ret i32 %r
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pa(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
