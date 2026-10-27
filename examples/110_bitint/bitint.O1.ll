; ModuleID = 'bitint.c'
source_filename = "bitint.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i64 @bitint_u100(i64 noundef %0, double noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i64 @cq_theta_ul(i64 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %5 = zext i64 %4 to i100    ; C: unsigned _BitInt(100) a = x;
  %6 = zext i64 %2 to i100    ; C: (unsigned _BitInt(100))c
  %7 = mul i100 %5, %6    ; C: a * c
  %8 = lshr i100 %5, 7    ; C: a >> 7
  %9 = add i100 %7, %8    ; C: a = a * c + (a >> 7);
  %10 = lshr i100 %9, 36    ; C: a >> 36
  %11 = trunc nuw i100 %10 to i64    ; C: (unsigned long)(a >> 36)
  %12 = tail call i64 @cq_measure_ul(i64 noundef %11) #4    ; C: cq_measure((unsigned long)(a >> 36))
  ret i64 %12    ; C: return
}

declare i64 @cq_theta_ul(i64 noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_ul(i64 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @bitint_s7(i64 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i64 @cq_theta_ul(i64 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %5 = trunc i64 %4 to i7    ; C: (_BitInt(7))x
  %6 = trunc i32 %2 to i7    ; C: (_BitInt(7))k
  %7 = tail call fastcc signext i7 @bump7(i7 noundef signext %5, i7 noundef signext %6)    ; C: _BitInt(7) s = bump7(...);
  %8 = sext i7 %7 to i32    ; C: (int)s
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #4    ; C: cq_measure((int)s)
  ret i32 %9    ; C: return
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc signext i7 @bump7(i7 noundef signext %0, i7 noundef signext %1) unnamed_addr #2 {
  %3 = add nsw i7 %1, %0    ; C: s + k
  ret i7 %3    ; C: return
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
