; spec_accept_dropped_arg_inplace_mc.ll — ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-hgwx, the WARNED sibling of bd vsfp; d88e probe `j02C`).
;
; THE DEFECT, on the oracle (`main` aee8f4f8). `t = h(q, m)` with `h(a, k) = k + 1`: the
; clone `__cq_q_h_01(q, m)` ignores `q`, but it still counted as a PRIOR USE of `q`, so
; M-C's G7 (`priorUseIsSettled`, ArithLowering.cpp arm (d)) refused to lower `u = t + q`
; IN PLACE: `cq_template_add_i32_hl(h, t)` minted a fresh rail, the Ry(.2) acted on it
; while `q` still carried the which-value record — a DEPHASED circuit (analytic, r1B
; §2: P(bit0 = 0) ~0.070 vs the twin's ~0.118), reported only by the lyyf-(B) warning
; `non-diagonal gate over a live derived record`. r1B's name-based mutant of arm (d)
; made it twin-identical; that mutant is UNSOUND for a quantum-verdict clone.
;
; THE FIX needs no change to M-C: the dead-argument drop removes the phantom read
; before any stage sees it (`h(0, m)`), so `q` has no prior user and `u = t + q` lowers
; IN PLACE as in the twin (`int t = m + 1;`): `cqrt_addc_i32(h, t)`, then Ry(.2) on the
; SAME handle, one measurement, no warning. RED on the oracle (out-of-place + warning).
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = t + q; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r); }
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
;
; Regenerate (the tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19):
;   clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o caller.ll
;   clang -O1 -emit-llvm -S lib.c -o lib.ll      (plain C, no CQ.h)
;   llvm-link -S caller.ll lib.ll -o <this file's body>
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOOOP < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @h(i32 noundef 0, i32 noundef %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_addc_i32(i32 [[Q]], i32 [[T]])
; CHECK:      call void @cqrt_ry_i32(i32 [[Q]], double 2.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 [[Q]])
; NOOOP-NOT: cq_template_add_i32
; NOOOP-NOT: __cq_q_h
; DROP: CQ_DEADARG_DBG: drop arg 0 of @h in @main (inst)
; DROP-NOT: warning

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = tail call i32 @h(i32 noundef %6, i32 noundef %5) #4
  %8 = add nsw i32 %7, %6
  %9 = icmp sgt i32 %5, 3
  br i1 %9, label %10, label %12

10:                                               ; preds = %2
  %11 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #4
  br label %12

12:                                               ; preds = %10, %2
  %13 = phi i32 [ %11, %10 ], [ %8, %2 ]
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  ret i32 %14
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
