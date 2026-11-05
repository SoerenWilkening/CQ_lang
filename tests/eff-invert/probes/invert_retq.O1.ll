; ModuleID = 'invert_retq.c'
source_filename = "invert_retq.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable

declare void @__cq_invert_begin() local_unnamed_addr #2

declare void @__cq_invert_end() local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_adjretq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %7) #4
  store i32 %0, ptr %7, align 4, !tbaa !6
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #5
  store i32 %8, ptr %7, align 4, !tbaa !6
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #5
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !12
  call fastcc void @twoq(ptr noundef nonnull %7, i32 noundef %9, double noundef %4, double noundef %5)
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !13
  tail call void @__cq_invert_end() #4
  %10 = load i32, ptr %7, align 4, !tbaa !6
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %10) #4
  %12 = tail call i32 @cq_measure_ui32(i32 noundef %9) #4
  %13 = add i32 %12, %11
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7) #4
  ret i32 %13
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @twoq(ptr nocapture noundef %0, i32 noundef %1, double noundef %2, double noundef %3) unnamed_addr #3 {
  %5 = icmp ugt i32 %1, 3
  %6 = load i32, ptr %0, align 4, !tbaa !6
  br i1 %5, label %7, label %9

7:                                                ; preds = %4
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %6, double noundef %2) #5
  store i32 %8, ptr %0, align 4, !tbaa !6
  ret void

9:                                                ; preds = %4
  %10 = tail call i32 @cq_theta_ui32(i32 noundef %6, double noundef %3) #5
  store i32 %10, ptr %0, align 4, !tbaa !6
  ret void
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i64 2147515342}
!11 = !{i64 2147515398}
!12 = !{i64 2147518282}
!13 = !{i64 2147518338}
