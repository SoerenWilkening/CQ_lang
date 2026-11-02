; ModuleID = 'mem_clone_pair_error.c'
source_filename = "mem_clone_pair_error.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@gang = local_unnamed_addr global double 0.000000e+00, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @i11(i32 noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #4
  store i32 %0, ptr %5, align 4, !tbaa !6
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  store i32 %6, ptr %5, align 4, !tbaa !6
  store double %3, ptr @gang, align 8, !tbaa !10
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !12
  call fastcc void @fa(ptr noundef nonnull %5, double noundef %2)
  call fastcc void @fb(ptr noundef nonnull %5)
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !13
  tail call void @__cq_invert_end() #4
  %7 = load i32, ptr %5, align 4, !tbaa !6
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #4
  ret i32 %8
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare void @__cq_invert_begin() local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @fa(ptr nocapture noundef %0, double noundef %1) unnamed_addr #3 {
  %3 = fmul double %1, 2.000000e+00
  store double %3, ptr @gang, align 8, !tbaa !10
  %4 = load i32, ptr %0, align 4, !tbaa !6
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #5
  store i32 %5, ptr %0, align 4, !tbaa !6
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @fb(ptr nocapture noundef %0) unnamed_addr #3 {
  %2 = load i32, ptr %0, align 4, !tbaa !6
  %3 = load double, ptr @gang, align 8, !tbaa !10
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %2, double noundef %3) #5
  store i32 %4, ptr %0, align 4, !tbaa !6
  ret void
}

declare void @__cq_invert_end() local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"double", !8, i64 0}
!12 = !{i64 2147512445}
!13 = !{i64 2147512501}
