; ModuleID = 'cond_flag_as_data.c'
source_filename = "cond_flag_as_data.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @flag_as_data(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %7 = icmp sgt i32 %6, %2    ; C: bool f = x > k;
  br i1 %7, label %8, label %10    ; C: if (f)

8:                                                ; preds = %5
  %9 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #2    ; C: cq_theta(&r, t);  (r = r0)
  br label %10

10:                                               ; preds = %8, %5
  %11 = phi i32 [ %9, %8 ], [ %3, %5 ]    ; C: r
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3    ; C: cq_measure(r)
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #3    ; C: cq_measure(f)
  %14 = zext i1 %13 to i32    ; C: (int)cq_measure(f)
  %15 = add nsw i32 %12, %14    ; C: cq_measure(r) + cq_measure(f)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %6) #3    ; C: cq_measure(x)
  %17 = add nsw i32 %15, %16    ; C: ... + cq_measure(x)
  ret i32 %17    ; C: return ...;
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @compare_shared_by_region_and_angle(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5, double noundef %6) local_unnamed_addr #0 {
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %9 = icmp eq i32 %8, %2    ; C: x == k  (one compare for both uses)
  br i1 %9, label %10, label %11    ; C: if (x == k)

10:                                               ; preds = %7
  tail call void @cq_phi(double noundef %4) #3    ; C: cq_phi(p);
  br label %11

11:                                               ; preds = %10, %7
  %12 = phi double [ %5, %10 ], [ %6, %7 ]    ; C: x == k ? a : b  (the angle, carried by the region merge)
  %13 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %12) #2    ; C: cq_theta(&r, ...);  (r = r0)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #3    ; C: cq_measure(r)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %8) #3    ; C: cq_measure(x)
  %16 = add nsw i32 %15, %14    ; C: cq_measure(r) + cq_measure(x)
  ret i32 %16    ; C: return ...;
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

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
