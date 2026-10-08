; control_classical_call_arm_twin_accept_verify_callsite_range.ll — ACCEPT (bd dm7f.21, R11 round 1 F1, the `intrinsicResultRange` member).
; control_classical_call_arm_twin_accept_verify_ctlz.ll's two-file clang -O1 module
; with ONE hand edit: `@F` computes `ctpop(G((x >> p) & 255))` under a call-site
; `range(i32 0, 9)`. The range is TRUE of the original (`@G` returns its argument,
; at most 8 bits set); clang stamps it when it can see through `@G`, and
; `callSiteReturnHolds` proves it on the original body through `returned`. In the
; twin `@G` reads `freeze(%4)`, any value, so the popcount can reach 32, the kept
; `range` makes it poison, and `@H(noundef poison)` was UB (round-1 snapshot
; 7ba76a01). Verified on the built twin, the range is unprovable: it is dropped
; and the result, still counted possibly poison, is frozen before `@H`.
; ANALYTIC (R2): on a UB-free execution of the source's `F(x, p)`, p < 32, the
; freezes are the identity and the dropped range held; otherwise UB or never merged.
;
; Mutant this kills: a builder that skips the verification pass (SpeculationTwin.cpp
; `getOrCreateSpeculationTwin` treating a freshly cloned twin as verified).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:       define internal i32 @__cq_specsafe_F(i32 noundef %0, i32 noundef %1)
; CHECK-NEXT:    %3 = lshr i32 %0, %1
; CHECK-NEXT:    %4 = and i32 %3, 255
; CHECK-NEXT:    %.fr = freeze i32 %4
; CHECK-NEXT:    %5 = tail call i32 @G(i32 noundef %.fr)
; CHECK-NEXT:    %6 = tail call i32 @llvm.ctpop.i32(i32 %5)
; CHECK-NEXT:    %.fr1 = freeze i32 %6
; CHECK-NEXT:    %7 = tail call i32 @H(i32 noundef %.fr1)

define i32 @F(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = lshr i32 %0, %1
  %4 = and i32 %3, 255
  %5 = tail call i32 @G(i32 noundef %4) #5
  %6 = tail call range(i32 0, 9) i32 @llvm.ctpop.i32(i32 %5)
  %7 = tail call i32 @H(i32 noundef %6) #5
  ret i32 %7
}

declare i32 @llvm.ctpop.i32(i32) #1

define i32 @ex(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #6
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call i32 @F(i32 noundef %0, i32 noundef %1)
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #7
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

define noundef i32 @G(i32 noundef returned %0) local_unnamed_addr #4 {
  ret i32 %0
}

define noundef i32 @H(i32 noundef %0) local_unnamed_addr #4 {
  %2 = xor i32 %0, 5
  ret i32 %2
}

attributes #0 = { mustprogress nofree noinline nosync nounwind willreturn memory(none) }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nounwind }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
attributes #5 = { nounwind willreturn memory(none) }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }
