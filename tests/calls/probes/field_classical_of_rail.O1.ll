; ModuleID = 'field_classical_of_rail.c'
source_filename = "field_classical_of_rail.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @e(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #3
  %3 = zext i8 %2 to i32
  %4 = and i32 %0, 7
  %5 = lshr i32 %3, %4
  %6 = and i32 %5, 1
  %7 = tail call fastcc i32 @g(i32 noundef %6)
  %8 = and i32 %3, 1
  %9 = mul i32 %0, 257
  %10 = xor i32 %8, %9
  %11 = tail call fastcc i32 @g(i32 noundef %10)
  %12 = icmp sgt i32 %0, 3
  %13 = lshr i32 %3, 1
  %14 = and i32 %13, 1
  %15 = mul i32 %0, 65537
  %16 = select i1 %12, i32 %14, i32 %15
  %17 = add nuw nsw i32 %11, %7
  %18 = tail call fastcc i32 @g(i32 noundef %16)
  %19 = add nuw nsw i32 %17, %18
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #4
  ret i32 %20
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc range(i32 0, 16777981) i32 @g(i32 noundef %0) unnamed_addr #2 {
  %2 = trunc i32 %0 to i8
  %3 = tail call fastcc i32 @h(i8 noundef zeroext %2)
  %4 = lshr i32 %0, 8
  %5 = add nuw nsw i32 %3, %4
  ret i32 %5
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc range(i32 0, 766) i32 @h(i8 noundef zeroext %0) unnamed_addr #2 {
  %2 = zext i8 %0 to i32
  %3 = mul nuw nsw i32 %2, 3
  ret i32 %3
}

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
