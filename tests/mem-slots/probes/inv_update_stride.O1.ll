; ModuleID = 'inv_update_stride.c'
source_filename = "inv_update_stride.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 -32768, 32768) i32 @inv_update_stride(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca [2 x i16], align 2
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #4
  %5 = trunc i32 %0 to i16
  store i16 %5, ptr %4, align 2, !tbaa !6
  %6 = getelementptr inbounds i8, ptr %4, i64 2
  %7 = trunc i32 %1 to i16
  store i16 %7, ptr %6, align 2, !tbaa !6
  %8 = tail call signext i16 @cq_theta_si16(i16 noundef signext %7, double noundef %2) #5
  store i16 %8, ptr %6, align 2, !tbaa !6
  call fastcc void @inc3(ptr noundef nonnull %4)
  %9 = load i16, ptr %6, align 2, !tbaa !6
  %10 = tail call signext i16 @cq_measure_si16(i16 noundef signext %9) #4
  %11 = sext i16 %10 to i32
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #4
  ret i32 %11
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i16 @cq_theta_si16(i16 noundef signext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @inc3(ptr nocapture noundef %0) unnamed_addr #3 {
  %2 = getelementptr inbounds i8, ptr %0, i64 2
  %3 = load i16, ptr %2, align 2, !tbaa !6
  %4 = mul i16 %3, 5
  store i16 %4, ptr %2, align 2, !tbaa !6
  ret void
}

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #2

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
!7 = !{!"short", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
; CHECK inv_update_stride: call fastcc void @__cq_q_inc3_1_inv0(ptr %{{p}}, i32 %{{old}})
; CHECK __cq_q_inc3_1_inv0: getelementptr inbounds i32, ptr %{{p}}, i64 1
; CHECK-COUNT __cq_q_inc3_1_inv0: getelementptr i8 0
; USERCHECK inv_update_stride
