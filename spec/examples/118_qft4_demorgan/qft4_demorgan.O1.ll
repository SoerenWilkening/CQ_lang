; ModuleID = 'qft4_demorgan.c'
source_filename = "qft4_demorgan.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 16) i32 @qft4_demorgan(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %0) #2    ; C: cq_theta(&c0, th);
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %0) #2    ; C: cq_theta(&c1, th);
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %0) #2    ; C: cq_theta(&c2, th);
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %0) #2    ; C: cq_theta(&c3, th);
  br i1 %5, label %6, label %7    ; C: if (c3)

6:                                                ; preds = %1
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #3    ; C: cq_phi(M_PI);
  br label %7    ; C: end of if

7:                                                ; preds = %6, %1
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %5, double noundef 0x3FF921FB54442D18) #2    ; C: cq_theta(&c3, M_PI / 2);
  %9 = xor i1 %8, true    ; C: !c3  (hoisted negation, used by the later conditions)
  %10 = select i1 %8, i1 %4, i1 false    ; C: c3 && c2
  br i1 %10, label %11, label %12    ; C: if (c3 && c2)

11:                                               ; preds = %7
  tail call void @cq_phi(double noundef 0xBFF921FB54442D18) #3    ; C: cq_phi(-M_PI / 2);
  br label %12    ; C: end of if

12:                                               ; preds = %7, %11
  br i1 %4, label %13, label %14    ; C: if (c2)

13:                                               ; preds = %12
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #3    ; C: cq_phi(M_PI);
  br label %14    ; C: end of if

14:                                               ; preds = %13, %12
  %15 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %4, double noundef 0x3FF921FB54442D18) #2    ; C: cq_theta(&c2, M_PI / 2);
  %16 = xor i1 %3, true    ; C: !c1
  %17 = select i1 %9, i1 true, i1 %16    ; C: !(c3 && c1) = !c3 || !c1  (De Morgan)
  br i1 %17, label %19, label %18    ; C: if (c3 && c1)  (branches inverted)

18:                                               ; preds = %14
  tail call void @cq_phi(double noundef 0xBFE921FB54442D18) #3    ; C: cq_phi(-M_PI / 4);
  br label %19    ; C: end of if

19:                                               ; preds = %14, %18
  %20 = xor i1 %15, true    ; C: !c2
  %21 = select i1 %20, i1 true, i1 %16    ; C: !(c2 && c1)
  br i1 %21, label %23, label %22    ; C: if (c2 && c1)  (inverted)

22:                                               ; preds = %19
  tail call void @cq_phi(double noundef 0xBFF921FB54442D18) #3    ; C: cq_phi(-M_PI / 2);
  br label %23    ; C: end of if

23:                                               ; preds = %19, %22
  br i1 %3, label %24, label %25    ; C: if (c1)

24:                                               ; preds = %23
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #3    ; C: cq_phi(M_PI);
  br label %25    ; C: end of if

25:                                               ; preds = %24, %23
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 0x3FF921FB54442D18) #2    ; C: cq_theta(&c1, M_PI / 2);
  %27 = xor i1 %2, true    ; C: !c0
  %28 = select i1 %9, i1 true, i1 %27    ; C: !(c3 && c0)
  br i1 %28, label %30, label %29    ; C: if (c3 && c0)  (inverted)

29:                                               ; preds = %25
  tail call void @cq_phi(double noundef 0xBFD921FB54442D18) #3    ; C: cq_phi(-M_PI / 8);
  br label %30    ; C: end of if

30:                                               ; preds = %25, %29
  %31 = select i1 %20, i1 true, i1 %27    ; C: !(c2 && c0)
  br i1 %31, label %33, label %32    ; C: if (c2 && c0)  (inverted)

32:                                               ; preds = %30
  tail call void @cq_phi(double noundef 0xBFE921FB54442D18) #3    ; C: cq_phi(-M_PI / 4);
  br label %33    ; C: end of if

33:                                               ; preds = %30, %32
  %34 = select i1 %26, i1 %2, i1 false    ; C: c1 && c0
  br i1 %34, label %35, label %36    ; C: if (c1 && c0)

35:                                               ; preds = %33
  tail call void @cq_phi(double noundef 0xBFF921FB54442D18) #3    ; C: cq_phi(-M_PI / 2);
  br label %36    ; C: end of if

36:                                               ; preds = %33, %35
  br i1 %2, label %37, label %38    ; C: if (c0)

37:                                               ; preds = %36
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #3    ; C: cq_phi(M_PI);
  br label %38    ; C: end of if

38:                                               ; preds = %37, %36
  %39 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 0x3FF921FB54442D18) #2    ; C: cq_theta(&c0, M_PI / 2);
  %40 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %39) #3    ; C: cq_measure(c0)
  %41 = zext i1 %40 to i32    ; C: cq_measure(c0)
  %42 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %26) #3    ; C: cq_measure(c1)
  %43 = select i1 %42, i32 2, i32 0    ; C: cq_measure(c1) << 1
  %44 = or disjoint i32 %43, %41    ; C: |
  %45 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %15) #3    ; C: cq_measure(c2)
  %46 = select i1 %45, i32 4, i32 0    ; C: cq_measure(c2) << 2
  %47 = or disjoint i32 %44, %46    ; C: |
  %48 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8) #3    ; C: cq_measure(c3)
  %49 = select i1 %48, i32 8, i32 0    ; C: cq_measure(c3) << 3
  %50 = or disjoint i32 %47, %49    ; C: |
  ret i32 %50    ; C: return
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

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
