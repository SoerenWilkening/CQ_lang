; ModuleID = 'mem_clone_global_error.c'
source_filename = "mem_clone_global_error.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@gang = local_unnamed_addr global double 0.000000e+00, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @i12(i32 noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  store double %3, ptr @gang, align 8, !tbaa !6
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !10
  tail call fastcc void @fd(i32 noundef %5)
  store double %2, ptr @gang, align 8, !tbaa !6
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !11
  tail call void @__cq_invert_end() #4
  %6 = tail call i32 @cq_measure_ui32(i32 noundef %5) #4
  ret i32 %6
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @__cq_invert_begin() local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @fd(i32 noundef %0) unnamed_addr #2 {
  %2 = icmp ugt i32 %0, 3
  br i1 %2, label %3, label %5

3:                                                ; preds = %1
  %4 = load double, ptr @gang, align 8, !tbaa !6
  tail call void @cq_phi(double noundef %4) #4
  br label %5

5:                                                ; preds = %3, %1
  ret void
}

declare void @__cq_invert_end() local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i64 2147510327}
!11 = !{i64 2147510383}
