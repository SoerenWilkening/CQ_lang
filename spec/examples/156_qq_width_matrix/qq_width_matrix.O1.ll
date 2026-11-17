; ModuleID = 'qq_width_matrix.c'
source_filename = "qq_width_matrix.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define signext i8 @sub_qq_i8(i8 noundef signext %0, i8 noundef signext %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef %2) #2
  %6 = tail call signext i8 @cq_theta_si8(i8 noundef signext %1, double noundef %3) #2
  %7 = sub i8 %5, %6
  %8 = tail call signext i8 @cq_measure_si8(i8 noundef signext %7) #3
  ret i8 %8
}

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #1

declare signext i8 @cq_measure_si8(i8 noundef signext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define signext i16 @shl_qq_i16(i16 noundef signext %0, i16 noundef signext %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call signext i16 @cq_theta_si16(i16 noundef signext %0, double noundef %2) #2
  %6 = tail call signext i16 @cq_theta_si16(i16 noundef signext %1, double noundef %3) #2
  %7 = and i16 %6, 7
  %8 = shl i16 %5, %7
  %9 = tail call signext i16 @cq_measure_si16(i16 noundef signext %8) #3
  ret i16 %9
}

declare signext i16 @cq_theta_si16(i16 noundef signext, double noundef) local_unnamed_addr #1

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @ashr_qq_i64(i64 noundef %0, i64 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i64 @cq_theta_sll(i64 noundef %0, double noundef %2) #2
  %6 = tail call i64 @cq_theta_sll(i64 noundef %1, double noundef %3) #2
  %7 = and i64 %6, 63
  %8 = ashr i64 %5, %7
  %9 = tail call i64 @cq_measure_sll(i64 noundef %8) #3
  ret i64 %9
}

declare i64 @cq_theta_sll(i64 noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_sll(i64 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @sdiv_qq_i32(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %3) #2
  %7 = sdiv i32 %5, %6
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @srem_qq_i32(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %3) #2
  %7 = srem i32 %5, %6
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @udiv_qq_i32(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #2
  %7 = udiv i32 %5, %6
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #3
  ret i32 %8
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @and_qq_i64(i64 noundef %0, i64 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i64 @cq_theta_sll(i64 noundef %0, double noundef %2) #2
  %6 = tail call i64 @cq_theta_sll(i64 noundef %1, double noundef %3) #2
  %7 = and i64 %6, %5
  %8 = tail call i64 @cq_measure_sll(i64 noundef %7) #3
  ret i64 %8
}

; Function Attrs: nounwind ssp uwtable
define float @fadd_qq_f32(float noundef %0, float noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call float @cq_theta_f32(float noundef %0, double noundef %2) #2
  %6 = tail call float @cq_theta_f32(float noundef %1, double noundef %3) #2
  %7 = fadd float %5, %6
  %8 = tail call float @cq_measure_f32(float noundef %7) #3
  ret float %8
}

declare float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #1

declare float @cq_measure_f32(float noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define float @fdiv_qq_f32(float noundef %0, float noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call float @cq_theta_f32(float noundef %0, double noundef %2) #2
  %6 = tail call float @cq_theta_f32(float noundef %1, double noundef %3) #2
  %7 = fdiv float %5, %6
  %8 = tail call float @cq_measure_f32(float noundef %7) #3
  ret float %8
}

; Function Attrs: nounwind ssp uwtable
define double @fdiv_qq_f64(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %2) #2
  %6 = tail call double @cq_theta_f64(double noundef %1, double noundef %3) #2
  %7 = fdiv double %5, %6
  %8 = tail call double @cq_measure_f64(double noundef %7) #3
  ret double %8
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

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
