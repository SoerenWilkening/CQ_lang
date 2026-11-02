; cq-jkq8 (CR rule 19, f684858: extra results are the union over the return paths by mint site, handle 0 on a
; path that did not mint one): mk is called as it is (no quantum argument, a body that rotates) and mints x on
; one classical path only; its kept clone returns x's handle there and handle 0 on the other path.
; CHECK __cq_q_mk_00: phi i32 [ %{{a}}, %{{b}} ], [ 0, %{{c}} ]
; USERCHECK use
; Source:
;   #include "CQ.h"
;   /* CR rule 19 (f684858): an in-place callee minting a register on one classical path only returns handle 0 for
;      it on the other path. */
;   static __attribute__((noinline)) int mk(int c, double th) {
;     int r = c;
;     if (c > 0) { int x = c; cq_theta(&x, th); r = x * 2; }
;     return r;
;   }
;   int use(int c, double th) {
;     int v = mk(c, th);
;     return cq_measure(v);
;   }
; ModuleID = 'mint.c'
source_filename = "mint.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @use(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @mk(i32 noundef %0, double noundef %1)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @mk(i32 noundef %0, double noundef %1) unnamed_addr #1 {
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %4, label %7

4:                                                ; preds = %2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %6 = shl nsw i32 %5, 1
  br label %7

7:                                                ; preds = %4, %2
  %8 = phi i32 [ %6, %4 ], [ %0, %2 ]
  ret i32 %8
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
