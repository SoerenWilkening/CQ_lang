; ModuleID = 'inv_update_image.c'
source_filename = "inv_update_image.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @inv_update_image(i32 noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca [2 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #4
  store i32 %0, ptr %5, align 4, !tbaa !6
  %6 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 %1, ptr %6, align 4, !tbaa !6
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %3) #5
  store i32 %7, ptr %5, align 4, !tbaa !6
  %8 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %3) #5
  store i32 %8, ptr %6, align 4, !tbaa !6
  call fastcc void @bump(ptr noundef nonnull %5, i32 noundef %2)
  %9 = load i32, ptr %5, align 4, !tbaa !6
  %10 = load i32, ptr %6, align 4, !tbaa !6
  %11 = add nsw i32 %10, %9
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #4
  ret i32 %11
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @bump(ptr nocapture noundef %0, i32 noundef %1) unnamed_addr #3 {
  %3 = load i32, ptr %0, align 4, !tbaa !6
  %4 = mul nsw i32 %3, 3
  %5 = add nsw i32 %4, %1
  store i32 %5, ptr %0, align 4, !tbaa !6
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
; CHECK inv_update_image: call fastcc void @__cq_q_bump_10_inv0(ptr %{{p}}, i32 %{{b}}, i32 %{{old}})
; CHECK inv_update_image: call i32 @cq_template_sub_i32(i32 %{{s}}, i32 %{{c1}})
; CHECK-COUNT inv_update_image: __cq_q_bump_10_unc( 0
; CHECK-ABSENT __cq_q_bump_10_unc
; USERCHECK inv_update_image
