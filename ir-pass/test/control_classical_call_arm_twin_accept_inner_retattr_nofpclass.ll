; control_classical_call_arm_twin_accept_inner_retattr_nofpclass.ll — ACCEPT (bd dm7f.21).
; FLIPPED from control_classical_call_arm_reject_inner_retattr_nofpclass.ll (bd bwfp
; R11 round 3 F1(c), a DECLINE) by the owner ruling of 2026-10-08 (option a).
; `@hc` returns `0/0 = NaN` for `%x == 0` under `nofpclass(nan)` (no `noundef`), i.e.
; poison. `@pc` compares it and returns the `zext` under `noundef`: `pc(0)` executes
; `ret noundef poison`, immediate UB the bare hoist would run on excluded basis
; states. LLVM 19's `hasPoisonGeneratingReturnAttributes` does not read `nofpclass`;
; the dataflow asks `returnAttrsHold` (the inert set plus a proven `range`), so the
; source stays counted. The hoist now calls `@pc`'s speculation-safe twin, whose `ret`
; is frozen. ANALYTIC (R2): for `%k != 0` `@hc` returns 1.0 (not NaN), nothing is
; poison, and the twin returns `pc(%k)`; for `%k = 0` the source's own call is UB
; under a true guard, and the twin's value is never merged under a false one.
; Decline neighbour, still refused: control_classical_call_arm_twin_reject_decl_own_noundef_range.ll
; (an unprovable return constraint under the bodyless callee's own `noundef`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_specsafe_pc(i32 %k)
; CHECK:       call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       define internal noundef i32 @__cq_specsafe_pc(i32 noundef %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %d = sitofp i32 %x to double
; CHECK-NEXT:    %h = call double @hc(double %d)
; CHECK-NEXT:    %b = fcmp oeq double %h, 1.000000e+00
; CHECK-NEXT:    %v = zext i1 %b to i32
; CHECK-NEXT:    %v.fr = freeze i32 %v
; CHECK-NEXT:    ret i32 %v.fr

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal nofpclass(nan) double @hc(double %x) #0 {
entry:
  %m = fdiv double %x, %x
  ret double %m
}

define internal noundef i32 @pc(i32 noundef %x) #0 {
entry:
  %d = sitofp i32 %x to double
  %h = call double @hc(double %d)
  %b = fcmp oeq double %h, 1.000000e+00
  %v = zext i1 %b to i32
  ret i32 %v
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @pc(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
