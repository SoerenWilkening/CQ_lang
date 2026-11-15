; cq-woqja (rule 16 noreturn; owner rulings 2026-11-11 Q7, 2026-11-14 scope of Q7 and Q1): an all-classical call of a
; DEFINED internal noreturn helper (quit: exit(3)) after a quantum abort, directly and through mid. quit's exit is the
; effect entry exit under a true seed, then abort_i1 of the seed, never the host call. Source:
; tests/eff-tape/probes/noreturn_defined_after_event.c.
; CHECK quit: call i32 @cqrt_alloc_i1(i1 true)
; CHECK quit: @.cq.effect.exit
; CHECK quit: call void @cqrt_abort_i1(
; CHECK-COUNT quit: @exit( 0
; CHECK mid: @quit(
; ModuleID = 'noreturn_defined_after_event.c'
source_filename = "noreturn_defined_after_event.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @caller(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %7, label %6

6:                                                ; preds = %2
  tail call void @abort() #6
  unreachable

7:                                                ; preds = %2
  %8 = and i32 %1, 2
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %11, label %10

10:                                               ; preds = %7
  tail call fastcc void @quit()
  unreachable

11:                                               ; preds = %7
  %12 = tail call i32 @cq_measure_si32(i32 noundef %3) #7
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #2

; Function Attrs: noinline noreturn nounwind ssp uwtable
define internal fastcc void @quit() unnamed_addr #3 {
  tail call void @exit(i32 noundef 3) #8
  unreachable
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @chain(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %7, label %6

6:                                                ; preds = %2
  tail call void @abort() #6
  unreachable

7:                                                ; preds = %2
  %8 = and i32 %1, 2
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %11, label %10

10:                                               ; preds = %7
  tail call fastcc void @mid()
  unreachable

11:                                               ; preds = %7
  %12 = tail call i32 @cq_measure_si32(i32 noundef %3) #7
  ret i32 %12
}

; Function Attrs: noinline noreturn nounwind ssp uwtable
define internal fastcc void @mid() unnamed_addr #3 {
  tail call fastcc void @quit()
  unreachable
}

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline noreturn nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { cold noreturn nounwind }
attributes #7 = { nounwind }
attributes #8 = { noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
