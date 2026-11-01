; FATAL: cq: unimplemented: spine: a rule 10 merge through a representation change whose constant incoming 0 arrives on an edge where its register may have been changed by
; cq-5ajv (review spine-h1 #1): clang -O1 of
;   int w4(void){
;     bool x=0,a=0,y=0,z=0;
;     cq_theta(&x,0.3); cq_theta(&a,1.0); cq_theta(&z, 0.9);
;     if (a) { y = x; cq_theta(&y,0.7); }
;     z ^= y;
;     if (z) cq_theta(&y, 0.2);
;     return cq_measure(y) | cq_measure(x)<<1 | cq_measure(a)<<2 | cq_measure(z)<<3;
;   }
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 16) i32 @w4() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.000000e-01) #2
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 1.000000e+00) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 9.000000e-01) #2
  br i1 %2, label %4, label %7

4:                                                ; preds = %0
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666) #2
  %6 = zext i1 %5 to i8
  br label %7

7:                                                ; preds = %4, %0
  %8 = phi i8 [ %6, %4 ], [ 0, %0 ]
  %9 = zext i1 %3 to i8
  %10 = icmp ne i8 %8, %9
  br i1 %10, label %11, label %15

11:                                               ; preds = %7
  %12 = trunc nuw i8 %8 to i1
  %13 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %12, double noundef 2.000000e-01) #2
  %14 = zext i1 %13 to i8
  br label %15

15:                                               ; preds = %11, %7
  %16 = phi i8 [ %14, %11 ], [ %8, %7 ]
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %17) #3
  %19 = zext i1 %18 to i32
  %20 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #3
  %21 = select i1 %20, i32 2, i32 0
  %22 = or disjoint i32 %21, %19
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #3
  %24 = select i1 %23, i32 4, i32 0
  %25 = or disjoint i32 %22, %24
  %26 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10) #3
  %27 = select i1 %26, i32 8, i32 0
  %28 = or disjoint i32 %25, %27
  ret i32 %28
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
