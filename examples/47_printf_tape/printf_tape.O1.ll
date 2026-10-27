; ModuleID = 'printf_tape.c'
source_filename = "printf_tape.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@.str.1 = private unnamed_addr constant [8 x i8] c"big %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [10 x i8] c"%d %d %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @printf_quantum(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %4 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %3)    ; C: printf("%d\n", x);
  %5 = tail call i32 @cq_measure_si32(i32 noundef %3) #4    ; C: cq_measure(x)
  ret i32 %5    ; C: return
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @printf_under_quantum_if(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %5 = icmp sgt i32 %4, %2    ; C: x > k
  br i1 %5, label %6, label %8    ; C: if (x > k)

6:                                                ; preds = %3
  %7 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, i32 noundef %4)    ; C: printf("big %d\n", x);
  br label %8    ; C: end of if

8:                                                ; preds = %6, %3
  %9 = tail call i32 @cq_measure_si32(i32 noundef %4) #4    ; C: cq_measure(x)
  ret i32 %9    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define i32 @printf_mixed(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %5 = add nsw i32 %4, %2    ; C: int y = x + c;
  %6 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.2, i32 noundef %4, i32 noundef %2, i32 noundef %5)    ; C: printf("%d %d %d\n", x, c, y);
  %7 = tail call i32 @cq_measure_si32(i32 noundef %5) #4    ; C: cq_measure(y)
  ret i32 %7    ; C: return
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
