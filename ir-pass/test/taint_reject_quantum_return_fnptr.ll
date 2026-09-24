; taint_reject_quantum_return_fnptr.ll — DECLINE (bd test_C_libtooling-3jru).
;
; Rule-13 round 3 r10: `g` (returns a register) has its ADDRESS taken and is
; called indirectly. Any use of such a function is refused, because no indirect
; call can be told apart from one that reaches it.
;
; Source (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   __attribute__((noinline)) int g(int k) { return cq_theta(k, 0.7); }
;   __attribute__((noinline)) int h(int k) { return k*5; }
;   typedef int (*F)(int);
;   __attribute__((noinline)) static int slice(int m, int n, F f) {
;     int q = cq_theta(0, 0.5);
;     int r = f(m);
;     int a = 7;
;     if ((q > 1) & (r == n)) a += 3;
;     return cq_measure(q) + cq_measure(a);
;   }
;   int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2]), argc > 5 ? h : g); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq taint escape: quantum value returned across a function boundary

; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r3/r10_fnptr.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r3/r10_fnptr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @g(i32 noundef %0) #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 0x3FE6666666666666) #5
  ret i32 %2
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %0) #2 {
  %2 = mul nsw i32 %0, 5
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #3 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = icmp sgt i32 %0, 5
  %10 = select i1 %9, ptr @h, ptr @g
  %11 = tail call fastcc i32 @slice(i32 noundef %5, i32 noundef %8, ptr noundef nonnull %10)
  ret i32 %11
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0, i32 noundef %1, ptr nocapture noundef readonly %2) unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #5
  %5 = tail call i32 %2(i32 noundef %0) #5, !callees !10
  %6 = icmp sgt i32 %4, 1
  %7 = icmp eq i32 %5, %1
  %8 = and i1 %6, %7
  %9 = select i1 %8, i32 10, i32 7
  %10 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{ptr @g, ptr @h}
