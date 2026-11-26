; /* tests/spine probe (CR rule 6 with rule 17, cq-hbydr): a chain of in-place updates before a cq_invert region whose
;  * last image the region reads, and whose in-region update is read after the end. The region's own rails are uncomputed
;  * inside it and the update recomputed after the end (rule 17); the chain before the region stays in place, and the
;  * recomputed update is in place on the old rail, as anywhere else. */
; #include <stdbool.h>
; int recompute(unsigned char r0, double tr, double tx, double ty) {
;   unsigned char rem = r0;
;   bool x = 0, y = 0;
;   cq_theta(&rem, tr);
;   rem ^= 77;
;   if (rem >= 5) cq_theta(&x, tx);
;   rem -= x ? 5 : 0;
;   if (rem >= 9) cq_theta(&y, ty);
;   rem -= y ? 9 : 0;
;   cq_invert_begin();
;   if (rem >= 5) cq_theta(&x, tx);
;   rem -= x ? 5 : 0;
;   rem -= y ? 3 : 0;
;   cq_invert_end();
;   rem -= x ? 7 : 0;
;   return cq_measure(rem) + cq_measure(x) + cq_measure(y);
; }
source_filename = "tests/spine/probes/rule6_invert_recompute.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 258) i32 @recompute(i8 noundef zeroext %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3
  %6 = xor i8 %5, 77
  %7 = icmp ugt i8 %6, 4
  br i1 %7, label %8, label %11

8:                                                ; preds = %4
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %2) #3
  %10 = zext i1 %9 to i8
  br label %11

11:                                               ; preds = %8, %4
  %12 = phi i8 [ %10, %8 ], [ 0, %4 ]
  %13 = trunc nuw i8 %12 to i1
  %14 = select i1 %13, i8 -5, i8 0
  %15 = add i8 %14, %6
  %16 = icmp ugt i8 %15, 8
  br i1 %16, label %17, label %19

17:                                               ; preds = %11
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %3) #3
  br label %19

19:                                               ; preds = %17, %11
  %20 = phi i1 [ %18, %17 ], [ false, %11 ]
  %21 = select i1 %20, i8 -9, i8 0
  %22 = add i8 %21, %15
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !6
  %23 = icmp ugt i8 %22, 4
  br i1 %23, label %24, label %27

24:                                               ; preds = %19
  %25 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef %2) #3
  %26 = zext i1 %25 to i8
  br label %27

27:                                               ; preds = %24, %19
  %28 = phi i8 [ %26, %24 ], [ %12, %19 ]
  %29 = trunc nuw i8 %28 to i1
  %30 = select i1 %29, i8 -5, i8 0
  %31 = select i1 %20, i8 -3, i8 0
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !7
  tail call void @__cq_invert_end() #4
  %32 = select i1 %29, i8 -7, i8 0
  %33 = add i8 %22, %31
  %34 = add i8 %33, %30
  %35 = add i8 %34, %32
  %36 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %35) #5
  %37 = zext i8 %36 to i32
  %38 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %29) #5
  %39 = zext i1 %38 to i32
  %40 = add nuw nsw i32 %39, %37
  %41 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %20) #5
  %42 = zext i1 %41 to i32
  %43 = add nuw nsw i32 %40, %42
  ret i32 %43
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: noduplicate
declare void @__cq_invert_begin() local_unnamed_addr #2

; Function Attrs: noduplicate
declare void @__cq_invert_end() local_unnamed_addr #2

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noduplicate "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { noduplicate nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{i64 2147513303}
!7 = !{i64 2147514374}
; USERCHECK recompute
; CHECK recompute: call void @cqrt_xorc_i8(i32 %{{r}}, i8 77)
; CHECK-COUNT recompute: @cqrt_add_i8( 5
; CHECK-COUNT recompute: @cq_template_add 0
; CHECK-COUNT recompute: @cq_template_xor 0
