; ModuleID = 'dicke4.c'
source_filename = "dicke4.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 16) i32 @dicke4() local_unnamed_addr #0 {
  %1 = tail call double @llvm.acos.f64(double 0x3FE6A09E667F3BCD)    ; C: 2.0 * acos(sqrt(2.0 / 4)) == 2.0 * acos(sqrt(1.0 / 2))  (SCS_{4,2} CCRy and SCS_{2,1} CRy angles, CSE)
  %2 = fmul double %1, 2.000000e+00    ; C: (the same)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %2) #3    ; C: if (s == 3) cq_theta(&q2, ...) of SCS_{4,2}: s == 3 holds classically (q4 = 1, q3 = 1), q2 == 0
  %4 = xor i1 %3, true    ; C: q4 ^= q2 (q4 == 1) and, CSE'd, q3 ^= q2 (q3 == 1): both are !q2
  br i1 %3, label %9, label %5    ; C: if (q3) cq_theta(&q2, ...) with q3 == !q2: branch inverted

5:                                                ; preds = %0
  %6 = tail call double @llvm.acos.f64(double 0x3FE279A74590331C)    ; C: 2.0 * acos(sqrt(1.0 / 3))
  %7 = fmul double %6, 2.000000e+00    ; C: (the same)
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef %7) #3    ; C: cq_theta(&q2, ...) under !q2
  br label %9    ; C: (join)

9:                                                ; preds = %5, %0
  %10 = phi i1 [ %8, %5 ], [ %3, %0 ]    ; C: q2 after the conditional rotation
  %11 = zext i1 %10 to i32    ; C: s = 2 * q3 + q2: the q2 term
  %12 = xor i1 %10, %4    ; C: q3 ^= q2  (then q3 ^= q1 with q1 == 0: folded)
  %13 = select i1 %12, i32 2, i32 0    ; C: 2 * q3
  %14 = or disjoint i32 %13, %11    ; C: s = 2 * q3 + q2
  %15 = icmp eq i32 %14, 3    ; C: s == 3
  br i1 %15, label %16, label %21    ; C: if (s == 3)

16:                                               ; preds = %9
  %17 = tail call double @llvm.acos.f64(double 0x3FEA20BD700C2C3E)    ; C: 2.0 * acos(sqrt(2.0 / 3))
  %18 = fmul double %17, 2.000000e+00    ; C: (the same)
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %18) #3    ; C: cq_theta(&q1, ...) with q1 == 0
  %20 = zext i1 %19 to i8    ; C: (q1 as a byte)
  br label %21    ; C: (join)

21:                                               ; preds = %16, %9
  %22 = phi i8 [ %20, %16 ], [ 0, %9 ]    ; C: q1 after the conditional rotation (0 on the other path)
  %23 = zext i1 %10 to i8    ; C: (q2 as a byte)
  %24 = icmp ne i8 %22, %23    ; C: q2 ^= q1  (SCS_{2,1})
  br i1 %24, label %25, label %29    ; C: if (q2)

25:                                               ; preds = %21
  %26 = trunc nuw i8 %22 to i1    ; C: (q1)
  %27 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %26, double noundef %2) #3    ; C: cq_theta(&q1, 2.0 * acos(sqrt(1.0 / 2)))
  %28 = zext i1 %27 to i8    ; C: (q1 as a byte)
  br label %29    ; C: (join)

29:                                               ; preds = %25, %21
  %30 = phi i8 [ %28, %25 ], [ %22, %21 ]    ; C: q1 after the conditional rotation
  %31 = zext i1 %12 to i8    ; C: (q3 as a byte)
  %32 = icmp ne i8 %22, %31    ; C: q3 ^= q1  (end of SCS_{3,2}; -O1 placed it here, it reads q1 before the SCS_{2,1} rotation)
  %33 = trunc nuw i8 %30 to i1    ; C: (q1)
  %34 = xor i1 %24, %33    ; C: q2 ^= q1
  %35 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %33) #4    ; C: cq_measure(q1)
  %36 = zext i1 %35 to i32    ; C: (bit 0)
  %37 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %34) #4    ; C: cq_measure(q2)
  %38 = select i1 %37, i32 2, i32 0    ; C: << 1
  %39 = or disjoint i32 %38, %36    ; C: |
  %40 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %32) #4    ; C: cq_measure(q3)
  %41 = select i1 %40, i32 4, i32 0    ; C: << 2
  %42 = or disjoint i32 %39, %41    ; C: |
  %43 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #4    ; C: cq_measure(q4)
  %44 = select i1 %43, i32 8, i32 0    ; C: << 3
  %45 = or disjoint i32 %42, %44    ; C: |
  ret i32 %45    ; C: return
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.acos.f64(double) #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
