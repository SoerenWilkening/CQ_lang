; cq-jkq8 (CR rule 13, f684858): a computed goto is a switch over its destination list. cg_quantum: a constant
; blockaddress table read at a quantum index (the case atoms are the index's equalities, the last entry's destination
; the complement); cg_classical: a classical index, a classical switch over the destinations.
; CHECK cg_classical: switch i32
; USERCHECK cg_quantum
; USERCHECK cg_classical
; Source (clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I CQ_spec):
;   #include "CQ.h"
;   /* CR rule 13 (f684858): a computed goto is a switch over its destination list. */
;   int cg_quantum(int x0, double th) {
;     static const void *tbl[] = {&&a, &&b, &&c, &&a};
;     int x = x0; cq_theta(&x, th);
;     int r;
;     goto *tbl[x & 3];
;   a: r = x + 3; goto done;
;   b: r = x * 5; goto done;
;   c: r = 7; cq_phi(th); goto done;
;   done: return cq_measure(r);
;   }
;   int cg_classical(int x0, double th, int k) {
;     static const void *tbl[] = {&&a, &&b};
;     int x = x0; cq_theta(&x, th);
;     int r;
;     goto *tbl[k & 1];
;   a: r = x + 3; goto done;
;   b: cq_theta(&x, th); r = x * 5; goto done;
;   done: return cq_measure(r);
;   }
; ModuleID = 'cgoto.c'
source_filename = "cgoto.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cg_quantum.tbl = internal unnamed_addr constant [4 x ptr] [ptr blockaddress(@cg_quantum, %8), ptr blockaddress(@cg_quantum, %10), ptr blockaddress(@cg_quantum, %12), ptr blockaddress(@cg_quantum, %8)], align 16
@cg_classical.tbl = internal unnamed_addr constant [2 x ptr] [ptr blockaddress(@cg_classical, %9), ptr blockaddress(@cg_classical, %11)], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @cg_quantum(i32 noundef %0, double noundef %1) #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %4 = and i32 %3, 3
  %5 = zext nneg i32 %4 to i64
  %6 = getelementptr inbounds [4 x ptr], ptr @cg_quantum.tbl, i64 0, i64 %5
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  indirectbr ptr %7, [label %8, label %10, label %12]

8:                                                ; preds = %2
  %9 = add nsw i32 %3, 3
  br label %13

10:                                               ; preds = %2
  %11 = mul nsw i32 %3, 5
  br label %13

12:                                               ; preds = %2
  tail call void @cq_phi(double noundef %1) #3
  br label %13

13:                                               ; preds = %12, %10, %8
  %14 = phi i32 [ %9, %8 ], [ 7, %12 ], [ %11, %10 ]
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #3
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @cg_classical(i32 noundef %0, double noundef %1, i32 noundef %2) #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = and i32 %2, 1
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [2 x ptr], ptr @cg_classical.tbl, i64 0, i64 %6
  %8 = load ptr, ptr %7, align 8, !tbaa !6
  indirectbr ptr %8, [label %9, label %11]

9:                                                ; preds = %3
  %10 = add nsw i32 %4, 3
  br label %14

11:                                               ; preds = %3
  %12 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %1) #2
  %13 = mul nsw i32 %12, 5
  br label %14

14:                                               ; preds = %11, %9
  %15 = phi i32 [ %10, %9 ], [ %13, %11 ]
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  ret i32 %16
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
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
