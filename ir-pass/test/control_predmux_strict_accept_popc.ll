; control_predmux_strict_accept_popc.ll — ACCEPT (bd dm7f.20).
; Ordinary C the PredMux strict classical-call path declined (bd dm7f.20):
;   __attribute__((noinline)) int h(int x){ return __builtin_popcount((unsigned)x); }
;   int ex(int k){ int q = 0; cq_theta(&q, 0.5); int y = q; if (q > 3) { if (h(k) == 2) y = q - k; else y = q + k; } return cq_measure(y); }
; IR: clang 19 -O1 of exactly that C, target attributes trimmed (R8).
;
; The nested classical condition `h(k) == 2` inside the tainted region is hoisted by
; the PredMux flatten, which demands a TOTAL call (`classicalCallCanBeSpeculated`:
; every defined input gives a defined result, no immediate UB). LLVM 19 InstCombine
; stamps `range(i32 0, 33)` on the ctpop call site; `totalCall` refused ANY
; poison-generating call-site return attribute (`intrinsicContractHolds`) and asked
; `canCreateUndefOrPoison` with flags on, so it declined. It now asks the owners the
; 6.5 dataflow asks (R12): `callSiteReturnHolds` proves the range from ctpop's
; semantics (at most 32 for an i32), and `createsPoison` (flags off, FlagProof.cpp)
; finds ctpop total. ANALYTIC: `h` is total, so the speculated value is the one the
; source computes on every basis state where it runs `h`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @ex(
; CHECK:       %[[R:[0-9]+]] = tail call i32 @h(i32 noundef %0)
; CHECK:       icmp {{eq|ne}} i32 %[[R]], 2
; CHECK:       call i32 @cq_template_and_i1_hl(
; CHECK:       call void @cqrt_copy_i32_controlled(

define range(i32 0, 33) i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call range(i32 0, 33) i32 @llvm.ctpop.i32(i32 %0)
  ret i32 %2
}

declare i32 @llvm.ctpop.i32(i32) #1

define i32 @ex(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  %3 = icmp sgt i32 %2, 3
  br i1 %3, label %4, label %11

4:                                                ; preds = %1
  %5 = tail call i32 @h(i32 noundef %0)
  %6 = icmp eq i32 %5, 2
  br i1 %6, label %7, label %9

7:                                                ; preds = %4
  %8 = sub nsw i32 %2, %0
  br label %11

9:                                                ; preds = %4
  %10 = add nsw i32 %2, %0
  br label %11

11:                                               ; preds = %7, %9, %1
  %12 = phi i32 [ %8, %7 ], [ %10, %9 ], [ %2, %1 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #5
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nounwind }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }
