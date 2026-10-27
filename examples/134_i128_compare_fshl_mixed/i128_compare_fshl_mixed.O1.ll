; ModuleID = 'i128_compare_fshl_mixed.c'
source_filename = "i128_compare_fshl_mixed.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i64 @i128_compare_merge(i64 noundef %0, double noundef %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i64 @cq_theta_ull(i64 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %6 = zext i64 %5 to i128    ; C: (unsigned __int128)x
  %7 = zext i64 %2 to i128    ; C: (unsigned __int128)c
  %8 = mul nuw i128 %6, %7    ; C: p = (unsigned __int128)x * c
  %9 = zext i64 %3 to i128    ; C: (unsigned __int128)lim
  %10 = shl nuw i128 %9, 64    ; C: (unsigned __int128)lim << 64
  %11 = icmp ugt i128 %8, %10    ; C: p > ((unsigned __int128)lim << 64)
  %12 = lshr i128 %8, 65    ; C: (p >> 1) >> 64  (then arm, folded with the final shift)
  %13 = add nuw i128 %8, 1    ; C: p + 1  (else arm)
  %14 = lshr i128 %13, 64    ; C: (p + 1) >> 64
  %15 = select i1 %11, i128 %12, i128 %14    ; C: r >> 64 for the chosen arm
  %16 = trunc nuw i128 %15 to i64    ; C: (unsigned long long)(r >> 64)
  %17 = tail call i64 @cq_measure_ull(i64 noundef %16) #4    ; C: cq_measure(...)
  ret i64 %17    ; C: return ...;
}

declare i64 @cq_theta_ull(i64 noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_ull(i64 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @fshl_mixed(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %5 = tail call i32 @llvm.fshl.i32(i32 %4, i32 %2, i32 3)    ; C: (x << 3) | (c >> 29)
  %6 = tail call i32 @cq_measure_ui32(i32 noundef %5) #4    ; C: cq_measure(...)
  ret i32 %6    ; C: return ...;
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.fshl.i32(i32, i32, i32) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
