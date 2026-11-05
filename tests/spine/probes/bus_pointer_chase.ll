; /* tests/spine probe (CR rules 5, 21): a pointer loaded from the bus is the address rail of the next access; the copy is
;  * overtaken by the store it addresses. A classical pointer stored as an i64 seed. */
; ModuleID = 'bus_pointer_chase.c'
source_filename = "bus_pointer_chase.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@A = global i32 1, align 4
@B = global i32 2, align 4
@slot = local_unnamed_addr global [2 x ptr] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define i32 @pointer_chase(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  store ptr @A, ptr @slot, align 16, !tbaa !6
  store ptr @B, ptr getelementptr inbounds (i8, ptr @slot, i64 8), align 8, !tbaa !6
  %5 = and i32 %4, 1
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [2 x ptr], ptr @slot, i64 0, i64 %6
  %8 = load ptr, ptr %7, align 8, !tbaa !6
  store i32 %2, ptr %8, align 4, !tbaa !10
  %9 = load i32, ptr @A, align 4, !tbaa !10
  %10 = load i32, ptr @B, align 4, !tbaa !10
  %11 = add nsw i32 %10, %9
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  ret i32 %12
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
; USERCHECK pointer_chase
