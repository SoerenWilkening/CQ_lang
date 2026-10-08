; control_classical_call_arm_twin_accept_verify_returned.ll — ACCEPT (bd dm7f.21, R11 round 1 F1).
; A plan read off the ORIGINAL body proved a flag through a `returned` callee whose
; argument the twin then FROZE. Two-file C, each TU at clang 19 -O1, llvm-linked
; (the run_slice_multi / cqc shape), target attributes trimmed (R8):
;   tu_g.c:    int G(int v) { return v; }  int H(int v) { return v ^ 5; }
;   tu_main.c: __attribute__((const)) int G(int v); __attribute__((const)) int H(int v);
;              __attribute__((noinline)) int F(unsigned x, unsigned p) {
;                return H(G((int)((x >> p) & 255u)) + 1); }
;              int ex(unsigned x, unsigned p) { int q = 0; cq_theta(&q, 0.0); int y = q;
;                if (q > 3) y = F(x, p); return cq_measure(y); }
; FunctionAttrs infers `define noundef i32 @G(i32 noundef returned %0)`. `%4` is
; poison for p >= 32, so the twin freezes it before `@G`'s `noundef` parameter.
; The round-1 plan then proved `add nsw %5, 1` from `%5` READ THROUGH `returned` as
; the original `%4` in [0, 255]; in the twin `%5` is `freeze(%4)`, any value, so the
; `nsw` can fail and `@H(noundef poison)` was immediate UB on a basis state the
; guard excluded (round-1 snapshot 7ba76a01: `%6` unfrozen). The builder now
; re-runs the twin-mode dataflow on the BUILT twin, where LLVM's known bits of
; `freeze(%4)` are unknown, and freezes the newly exposed sink.
; ANALYTIC (R2): on a basis state where the source runs `F(x, p)` without UB, p < 32
; and both freezes are the identity; otherwise the source is UB or the value is
; never merged.
;
; Mutant this kills: a builder that skips the verification pass (SpeculationTwin.cpp
; `getOrCreateSpeculationTwin` treating a freshly cloned twin as verified).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @ex(
; CHECK:       tail call i32 @__cq_specsafe_F(i32 noundef %0, i32 noundef %1)
; CHECK:       define internal i32 @__cq_specsafe_F(i32 noundef %0, i32 noundef %1)
; CHECK-NEXT:    %3 = lshr i32 %0, %1
; CHECK-NEXT:    %4 = and i32 %3, 255
; CHECK-NEXT:    %.fr = freeze i32 %4
; CHECK-NEXT:    %5 = tail call i32 @G(i32 noundef %.fr)
; CHECK-NEXT:    %6 = add nsw i32 %5, 1
; CHECK-NEXT:    %.fr1 = freeze i32 %6
; CHECK-NEXT:    %7 = tail call i32 @H(i32 noundef %.fr1)

define noundef i32 @G(i32 noundef returned %0) local_unnamed_addr #0 {
  ret i32 %0
}

define noundef i32 @H(i32 noundef %0) local_unnamed_addr #0 {
  %2 = xor i32 %0, 5
  ret i32 %2
}

define i32 @F(i32 noundef %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = lshr i32 %0, %1
  %4 = and i32 %3, 255
  %5 = tail call i32 @G(i32 noundef %4) #4
  %6 = add nsw i32 %5, 1
  %7 = tail call i32 @H(i32 noundef %6) #4
  ret i32 %7
}

define i32 @ex(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #5
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call i32 @F(i32 noundef %0, i32 noundef %1)
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #6
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { mustprogress nofree noinline nosync nounwind willreturn memory(none) }
attributes #2 = { nounwind }
attributes #4 = { nounwind willreturn memory(none) }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }
