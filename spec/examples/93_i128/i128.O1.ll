; ModuleID = 'i128.c'
source_filename = "i128.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i64 @mul_i128(i64 noundef %0, double noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i64 @cq_theta_ull(i64 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = zext i64 %4 to i128    ; C: (unsigned __int128)x
  %6 = zext i64 %2 to i128    ; C: (unsigned __int128)c
  %7 = or disjoint i128 %5, 18446744073709551616    ; C: p + (c << 64) rewritten by -O1 as (x | 1<<64) * c
  %8 = mul i128 %7, %6    ; C: (x | 1<<64) * c
  %9 = lshr i128 %8, 64    ; C: q >> 64
  %10 = trunc nuw i128 %9 to i64    ; C: (unsigned long long)(q >> 64)
  %11 = tail call i64 @cq_measure_ull(i64 noundef %10) #3    ; C: cq_measure(...)
  ret i64 %11    ; C: return
}

declare i64 @cq_theta_ull(i64 noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_ull(i64 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @div_i128(i64 noundef %0, double noundef %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i64 @cq_theta_ull(i64 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %6 = zext i64 %2 to i128    ; C: (unsigned __int128)c
  %7 = shl nuw i128 %6, 64    ; C: (unsigned __int128)hi << 64
  %8 = zext i64 %3 to i128    ; C: (unsigned __int128)lo
  %9 = or disjoint i128 %7, %8    ; C: n = (hi << 64) | lo
  %10 = zext i64 %5 to i128    ; C: (unsigned __int128)x
  %11 = or disjoint i128 %10, 18446744073709551616    ; C: d = x | (1 << 64)
  %12 = udiv i128 %9, %11    ; C: n / d
  %13 = trunc nuw i128 %12 to i64    ; C: (unsigned long long)(n / d)
  %14 = tail call i64 @cq_measure_ull(i64 noundef %13) #3    ; C: cq_measure(...)
  ret i64 %14    ; C: return
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
