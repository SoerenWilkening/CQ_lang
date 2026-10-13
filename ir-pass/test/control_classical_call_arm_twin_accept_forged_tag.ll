; control_classical_call_arm_twin_accept_forged_tag.ll — ACCEPT (batch 053, bd r2j3.22).
; A module that FORGES a speculation-safe twin: a user function named
; `@__cq_specsafe_f` carrying `!cq.specsafe.twin !{ptr @f}` with a WRONG body
; (`ret i32 999`). Before r2j3.22 `findTwin` looked the twin up by that name and
; trusted the tag, so the 6.5 hoist called the forged body: on any basis state where
; the guard holds, `%out` would receive 999 instead of `f(k)`, a verify-clean silent
; miscompile (the 9oob family: a user `__cq_q_*_unc` twin with a wrong body is
; trusted). Not buildable from C (metadata); a hand-IR latent hazard.
; Now the twin is found only through the pass's own registry of the twins it built
; and verified (SpeculationTwin.cpp), cross-checked against the tag. The forged
; function is not in it, so the pass builds and verifies its own twin (renamed by
; the symbol table past the user's, `@__cq_specsafe_f.<n>`) and leaves the forged
; one untouched and uncalled. Note the two tags print as ONE uniqued node `!{ptr @f}`:
; the tag cannot tell a built twin from a forged one, which is why it is never the
; evidence. Everything else is
; control_classical_call_arm_twin_accept_nsw_inner_noundef.ll, whose analytic
; argument the built twin carries.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define internal i32 @__cq_specsafe_f(i32 noundef %0) !cq.specsafe.twin !{{[0-9]+}} {
; CHECK-NEXT:    ret i32 999
; CHECK-LABEL: define i32 @ex(
; CHECK:       tail call i32 @[[TWIN:__cq_specsafe_f\.[0-9]+]](i32 noundef %0)
; CHECK-NOT:   call i32 @__cq_specsafe_f(
; CHECK-NOT:   call i32 @f(
; CHECK:       define internal i32 @[[TWIN]](i32 noundef %0) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TW:[0-9]+]] {
; CHECK-NEXT:    %2 = add nsw i32 %0, 1
; CHECK-NEXT:    %.fr = freeze i32 %2
; CHECK-NEXT:    %3 = tail call i32 @g(i32 noundef %.fr)
; CHECK-NEXT:    %.fr1 = freeze i32 %3
; CHECK-NEXT:    ret i32 %.fr1
; CHECK:       ![[TW]] = !{ptr @f}

define range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = add nsw i32 %0, 1
  %3 = tail call i32 @g(i32 noundef %2)
  ret i32 %3
}

define internal i32 @__cq_specsafe_f(i32 noundef %0) !cq.specsafe.twin !0 {
  ret i32 999
}

define i32 @ex(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #2
  %3 = icmp sgt i32 %2, 3
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @f(i32 noundef %0)
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!0 = !{ptr @f}
