; iosink_accept_noio_mux_control.ll — ACCEPT (Rule-13 round 5 control for F-R5-1).
; The same program as iosink_reject_mux_literal_inmain.ll WITHOUT the printf: the
; merge is an ordinary 4.4 data select and `v*m` was always quantum. Unchanged
; by the IO-sink re-seed (byte-identical to aad63450).
;
; Source (clang -O1 -include CQ.h):
;   #include <stdio.h>
;   #include <stdlib.h>
;   int main(int argc, char **argv) { int m = atoi(argv[1]), n = atoi(argv[2]);
;     int q2 = 0; cq_theta(&q2, .5); int q = m; cq_theta(&q, .5); int v = 3;
;     if (q > 5) { v = 7; }
;     int a = 7; if ((q2 > 1) & (v * m == n)) a += 3;
;     return cq_measure(a) + cq_measure(q2); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; CHECK: call i32 @cq_template_mul_i32_hl(

; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r5/k12_noio_control.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2b9793f123da59f8/te_scratch/r5/k12_noio_control.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %10 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #3
  %11 = icmp sgt i32 %10, 5
  %12 = select i1 %11, i32 7, i32 3
  %13 = icmp sgt i32 %9, 1
  %14 = mul nsw i32 %12, %5
  %15 = icmp eq i32 %14, %8
  %16 = and i1 %13, %15
  %17 = select i1 %16, i32 10, i32 7
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #3
  %19 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  %20 = add nsw i32 %19, %18
  ret i32 %20
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
