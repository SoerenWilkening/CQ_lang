; ModuleID = 'mem_clone_qrom_error.c'
source_filename = "mem_clone_qrom_error.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tbl = local_unnamed_addr global [4 x i8] zeroinitializer, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @i10(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, double noundef %4, i8 noundef zeroext %5) local_unnamed_addr #0 {
  %7 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %7) #4
  store i32 %1, ptr %7, align 4, !tbaa !6
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #5
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %2) #5
  store i32 %9, ptr %7, align 4, !tbaa !6
  store i32 0, ptr @tbl, align 4
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !10
  call fastcc void @setup(ptr noundef nonnull %7, double noundef %3, i8 noundef zeroext %5)
  %10 = and i32 %8, 3
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [4 x i8], ptr @tbl, i64 0, i64 %11
  %13 = load i8, ptr %12, align 1, !tbaa !11
  %14 = icmp eq i8 %13, 0
  br i1 %14, label %16, label %15

15:                                               ; preds = %6
  tail call void @cq_phi(double noundef %4) #4
  br label %16

16:                                               ; preds = %6, %15
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !12
  tail call void @__cq_invert_end() #4
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %8) #4
  %18 = load i32, ptr %7, align 4, !tbaa !6
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %18) #4
  %20 = mul i32 %19, 7
  %21 = add i32 %20, %17
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7) #4
  ret i32 %21
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare void @__cq_invert_begin() local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @setup(ptr nocapture noundef %0, double noundef %1, i8 noundef zeroext %2) unnamed_addr #3 {
  store i8 %2, ptr getelementptr inbounds (i8, ptr @tbl, i64 1), align 1, !tbaa !11
  store i8 %2, ptr getelementptr inbounds (i8, ptr @tbl, i64 2), align 2, !tbaa !11
  %4 = load i32, ptr %0, align 4, !tbaa !6
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #5
  store i32 %5, ptr %0, align 4, !tbaa !6
  ret void
}

declare void @cq_phi(double noundef) local_unnamed_addr #2

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
!10 = !{i64 2147512579}
!11 = !{!8, !8, i64 0}
!12 = !{i64 2147512635}
