; ModuleID = 'indexed_clean.c'
source_filename = "indexed_clean.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @indexed_clean(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5, i32 noundef %6) local_unnamed_addr #0 {
  %8 = alloca [5 x i32], align 16
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %10 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #4
  %11 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %5) #4
  call void @llvm.lifetime.start.p0(i64 20, ptr nonnull %8) #5
  store i32 %9, ptr %8, align 16, !tbaa !6
  %12 = getelementptr inbounds i8, ptr %8, i64 4
  store i32 %10, ptr %12, align 4, !tbaa !6
  %13 = getelementptr inbounds i8, ptr %8, i64 8
  store i32 7, ptr %13, align 8, !tbaa !6
  %14 = getelementptr inbounds i8, ptr %8, i64 12
  store i32 %11, ptr %14, align 4, !tbaa !6
  %15 = getelementptr inbounds i8, ptr %8, i64 16
  store i32 9, ptr %15, align 16, !tbaa !6
  call void @llvm.memmove.p0.p0.i64(ptr noundef nonnull align 4 dereferenceable(12) %12, ptr noundef nonnull align 16 dereferenceable(12) %8, i64 12, i1 false)
  %16 = urem i32 %6, 5
  %17 = zext nneg i32 %16 to i64
  %18 = getelementptr inbounds [5 x i32], ptr %8, i64 0, i64 %17
  %19 = load i32, ptr %18, align 4, !tbaa !6
  %20 = xor i32 %19, 3
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #5
  call void @llvm.lifetime.end.p0(i64 20, ptr nonnull %8) #5
  ret i32 %21
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memmove.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i1 immarg) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
; CHECK-COUNT indexed_clean: call void @cqrt_copy_i32( 1
; CHECK indexed_clean: or i1 %{{a}}, %{{b}}
; CHECK indexed_clean: call void @cq_template_xor_i32_hl_unc(i32 %{{t}}, i32 %{{r}}, i32 3)
; CHECK-COUNT indexed_clean: call void @cqrt_free( 4
; USERCHECK indexed_clean
