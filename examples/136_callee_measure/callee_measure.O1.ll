; ModuleID = 'callee_measure.c'
source_filename = "callee_measure.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @callee_measure(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %6 = add nsw i32 %5, %3    ; C: int y = x + c;
  %7 = tail call fastcc i32 @readout(i32 noundef %5, i32 noundef %2)    ; C: int m = readout(x, k);
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6) #5    ; C: cq_measure(y)
  %9 = add nsw i32 %8, %7    ; C: m + cq_measure(y)
  ret i32 %9    ; C: return ...;
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @readout(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = tail call i32 @cq_measure_si32(i32 noundef %0) #5    ; C: int m = cq_measure(v);
  %4 = tail call i32 @llvm.smax.i32(i32 %3, i32 %1)    ; C: m > k ? m : k
  ret i32 %4    ; C: return ...;
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
