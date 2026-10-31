; ModuleID = 'narrow_quantum_return.c'
source_filename = "narrow_quantum_return.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define zeroext i1 @narrow_return_bool(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = icmp sgt i32 %4, %2
  ret i1 %5
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define signext i16 @narrow_return_short(i16 noundef signext %0, double noundef %1, i16 noundef signext %2) local_unnamed_addr #0 {
  %4 = tail call signext i16 @cq_theta_si16(i16 noundef signext %0, double noundef %1) #2
  %5 = add i16 %4, %2
  ret i16 %5
}

declare signext i16 @cq_theta_si16(i16 noundef signext, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @wide_return_long(i64 noundef %0, double noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef %1) #2
  %5 = xor i64 %4, %2
  ret i64 %5
}

declare i64 @cq_theta_sl(i64 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @narrow_bool_consumer(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %5 = icmp sgt i32 %4, %2
  %6 = select i1 %5, i32 5, i32 2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  ret i32 %7
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 -32768, 32768) i32 @narrow_short_consumer(i16 noundef signext %0, double noundef %1, i16 noundef signext %2) local_unnamed_addr #0 {
  %4 = tail call signext i16 @cq_theta_si16(i16 noundef signext %0, double noundef %1) #2
  %5 = add i16 %4, %2
  %6 = shl i16 %5, 1
  %7 = tail call signext i16 @cq_measure_si16(i16 noundef signext %6) #3
  %8 = sext i16 %7 to i32
  ret i32 %8
}

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @wide_long_consumer(i64 noundef %0, double noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef %1) #2
  %5 = xor i64 %4, %2
  %6 = add nsw i64 %5, 1
  %7 = tail call i64 @cq_measure_sl(i64 noundef %6) #3
  ret i64 %7
}

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #1

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
