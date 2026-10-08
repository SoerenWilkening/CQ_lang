; control_classical_call_arm_twin_accept_verify_ctlz.ll — ACCEPT (bd dm7f.21, R11 round 1 F1, the `isKnownNonZero` member).
; The F1 root cause reaching the ctlz poison-flag proof. Two-file C, each TU at
; clang 19 -O1, llvm-linked, target attributes trimmed (R8):
;   tu_g.c:    int G(int v) { return v; }  int H(int v) { return v ^ 5; }
;   tu_main.c: __attribute__((const)) int G(int v); __attribute__((const)) int H(int v);
;              __attribute__((noinline)) int F(unsigned x, unsigned p) {
;                return H(__builtin_clz((unsigned)G((int)((x >> p) | 1u)))); }
;              int ex(unsigned x, unsigned p) { int q = 0; cq_theta(&q, 0.0); int y = q;
;                if (q > 3) y = F(x, p); return cq_measure(y); }
; The twin freezes `%4 = or (x >> p), 1` (poison for p >= 32) before `@G`. On the
; original body `isKnownNonZero(%5)` reads `%5` through `returned` as `%4` (bit 0
; set), so the round-1 plan proved `ctlz(%5, is_zero_poison=true)` defined and left
; `@H`'s argument unfrozen (snapshot 7ba76a01). In the twin `%5` is `freeze(%4)`,
; possibly 0, so the ctlz is poison and `@H(noundef poison)` is UB. Verified on the
; built twin, the flag is unproven and `%6` is frozen.
; ANALYTIC (R2): on a UB-free execution of the source's `F(x, p)`, p < 32, `%4` is
; odd, both freezes are the identity; otherwise UB in the source or never merged.
;
; Mutant this kills: a builder that skips the verification pass (SpeculationTwin.cpp
; `getOrCreateSpeculationTwin` treating a freshly cloned twin as verified).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:       define internal i32 @__cq_specsafe_F(i32 noundef %0, i32 noundef %1)
; CHECK-NEXT:    %3 = lshr i32 %0, %1
; CHECK-NEXT:    %4 = or i32 %3, 1
; CHECK-NEXT:    %.fr = freeze i32 %4
; CHECK-NEXT:    %5 = tail call i32 @G(i32 noundef %.fr)
; CHECK-NEXT:    %6 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %5, i1 true)
; CHECK-NEXT:    %.fr1 = freeze i32 %6
; CHECK-NEXT:    %7 = tail call i32 @H(i32 noundef %.fr1)

define i32 @F(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = lshr i32 %0, %1
  %4 = or i32 %3, 1
  %5 = tail call i32 @G(i32 noundef %4) #5
  %6 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %5, i1 true)
  %7 = tail call i32 @H(i32 noundef %6) #5
  ret i32 %7
}

declare i32 @llvm.ctlz.i32(i32, i1 immarg) #1

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
