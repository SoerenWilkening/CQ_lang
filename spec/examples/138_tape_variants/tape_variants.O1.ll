; ModuleID = 'tape_variants.c'
source_filename = "tape_variants.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%f\0A\00", align 1
@.str.1 = private unnamed_addr constant [12 x i8] c"both %d %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [10 x i8] c"inner %d\0A\00", align 1
@.str.3 = private unnamed_addr constant [10 x i8] c"outer %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @printf_double(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %4 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, double noundef %3)    ; C: printf("%f\n", x);
  %5 = tail call double @cq_measure_f64(double noundef %3) #4    ; C: cq_measure(x)
  %6 = fcmp ogt double %5, 0.000000e+00    ; C: cq_measure(x) > 0.0
  %7 = zext i1 %6 to i32    ; C: (int)
  ret i32 %7    ; C: return ...;
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @printf_compound_cond(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3    ; C: cq_theta(&x, tx);
  %8 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %3) #3    ; C: cq_theta(&y, ty);
  %9 = icmp sgt i32 %7, %4    ; C: x > k
  %10 = icmp sgt i32 %8, %5    ; C: y > m
  %11 = select i1 %9, i1 %10, i1 false    ; C: x > k && y > m
  br i1 %11, label %12, label %14    ; C: if (x > k && y > m)

12:                                               ; preds = %6
  %13 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, i32 noundef %7, i32 noundef %8)    ; C: printf("both %d %d\n", x, y);
  br label %14

14:                                               ; preds = %12, %6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %7) #4    ; C: cq_measure(x)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %8) #4    ; C: cq_measure(y)
  %17 = add nsw i32 %16, %15    ; C: cq_measure(x) + cq_measure(y)
  ret i32 %17    ; C: return ...;
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @printf_nested_cond(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3    ; C: cq_theta(&x, tx);
  %8 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %3) #3    ; C: cq_theta(&y, ty);
  %9 = icmp sgt i32 %7, %4    ; C: x > k
  br i1 %9, label %10, label %16    ; C: if (x > k)

10:                                               ; preds = %6
  %11 = icmp sgt i32 %8, %5    ; C: y > m
  br i1 %11, label %12, label %14    ; C: if (y > m)

12:                                               ; preds = %10
  %13 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, i32 noundef %8)    ; C: printf("inner %d\n", y);
  br label %14

14:                                               ; preds = %12, %10
  %15 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.3, i32 noundef %7)    ; C: printf("outer %d\n", x);
  br label %16

16:                                               ; preds = %14, %6
  %17 = tail call i32 @cq_measure_si32(i32 noundef %7) #4    ; C: cq_measure(x)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %8) #4    ; C: cq_measure(y)
  %19 = add nsw i32 %18, %17    ; C: cq_measure(x) + cq_measure(y)
  ret i32 %19    ; C: return ...;
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
