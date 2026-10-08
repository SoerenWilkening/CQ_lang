; control_classical_call_arm_twin_accept_verify_freeze_range.ll — ACCEPT (bd dm7f.21, R11 round 1 F2).
; Facts read THROUGH a pre-existing `freeze` of a call the twin redirects. Hand IR
; (the reviewer's probe p2; clang -O1 InstCombine drops a freeze of a `noundef`
; value, so C does not reach it). Every attribute is true of the original: `@G`'s
; `noundef range(i32 0, 8)` holds whenever `@G` does not hit UB, and `G(INT_MAX)` is
; UB (`ret noundef poison` from the `nsw`), which forces `@F`'s twin to call
; `@G`'s twin. That twin drops the range and returns `freeze(%r)`, any value for
; x = INT_MAX. LLVM's known bits of `freeze %r` read through a guaranteed-not-poison
; (`noundef`) operand, so the round-1 plan proved `add nuw %f, 5` from the DROPPED
; range and left `@h(noundef %y)` unfrozen (snapshot 7ba76a01: UB on excluded basis
; states). Verified on the built twin, the call has no range, `nuw` is unproven and
; `%y` is frozen.
; ANALYTIC (R2): on a UB-free execution of the source's `F(%k)`, `%k < INT_MAX`,
; every freeze is the identity; otherwise UB in the source or never merged.
;
; Mutant this kills: a builder that skips the verification pass (SpeculationTwin.cpp
; `getOrCreateSpeculationTwin` treating a freshly cloned twin as verified).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:       define internal noundef i32 @__cq_specsafe_G(i32 noundef %x)
; CHECK:       define internal i32 @__cq_specsafe_F(i32 noundef %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %x.fr = freeze i32 %x
; CHECK-NEXT:    %r = call i32 @__cq_specsafe_G(i32 noundef %x.fr)
; CHECK-NEXT:    %f = freeze i32 %r
; CHECK-NEXT:    %y = add nuw i32 %f, 5
; CHECK-NEXT:    %y.fr = freeze i32 %y
; CHECK-NEXT:    %z = call i32 @h(i32 noundef %y.fr)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal noundef range(i32 0, 8) i32 @G(i32 noundef %x) #0 {
entry:
  %a = add nsw i32 %x, 1
  %r = and i32 %a, 7
  ret i32 %r
}

define internal noundef i32 @h(i32 noundef %v) #0 {
entry:
  %w = xor i32 %v, 3
  ret i32 %w
}

define internal i32 @F(i32 noundef %x) #0 {
entry:
  %r = call i32 @G(i32 noundef %x)
  %f = freeze i32 %r
  %y = add nuw i32 %f, 5
  %z = call i32 @h(i32 noundef %y)
  ret i32 %z
}

define i32 @example(i32 noundef %u0, i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @F(i32 %k)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }
