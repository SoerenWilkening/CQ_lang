; ModuleID = 'int_ops.c'
source_filename = "int_ops.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @sub_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = sub nsw i32 %4, %2    ; C: x - c
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #3    ; C: cq_measure(x - c)
  ret i32 %6    ; C: return
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @mul_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2    ; C: cq_theta(&x, tx);
  %6 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %3) #2    ; C: cq_theta(&y, ty);
  %7 = mul nsw i32 %6, %5    ; C: x * y
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3    ; C: cq_measure(x * y)
  ret i32 %8    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define i32 @shl_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = shl i32 %4, %2    ; C: x << c
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #3    ; C: cq_measure(x << c)
  ret i32 %6    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define i32 @lshr_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #2    ; C: cq_theta(&x, tx);
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #2    ; C: cq_theta(&y, ty);
  %7 = lshr i32 %5, %6    ; C: x >> y
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #3    ; C: cq_measure(x >> y)
  ret i32 %8    ; C: return
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @ashr_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = ashr i32 %4, %2    ; C: x >> c
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #3    ; C: cq_measure(x >> c)
  ret i32 %6    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define i32 @and_qc(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = and i32 %4, %2    ; C: x & c
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #3    ; C: cq_measure(x & c)
  ret i32 %6    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define i32 @or_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2    ; C: cq_theta(&x, tx);
  %6 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %3) #2    ; C: cq_theta(&y, ty);
  %7 = or i32 %6, %5    ; C: x | y
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3    ; C: cq_measure(x | y)
  ret i32 %8    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define i32 @xor_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #2    ; C: cq_theta(&x, tx);
  %6 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %3) #2    ; C: cq_theta(&y, ty);
  %7 = xor i32 %6, %5    ; C: x ^ y
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3    ; C: cq_measure(x ^ y)
  ret i32 %8    ; C: return
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
