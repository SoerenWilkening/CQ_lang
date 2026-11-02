; ModuleID = 'record_params.c'
source_filename = "record_params.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.big = type { i64, i64, i64 }
%struct.R = type { ptr, i64, i64 }

; Function Attrs: nounwind ssp uwtable
define i64 @two_rec(i64 noundef %0, double noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = alloca %struct.big, align 8
  %5 = alloca %struct.big, align 8
  %6 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %4) #6
  store i64 %6, ptr %4, align 8, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %4, i64 8
  store i64 %2, ptr %7, align 8, !tbaa !11
  %8 = getelementptr inbounds i8, ptr %4, i64 16
  store i64 1, ptr %8, align 8, !tbaa !12
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %5) #6
  store i64 %2, ptr %5, align 8, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %5, i64 8
  store i64 %6, ptr %9, align 8, !tbaa !11
  %10 = getelementptr inbounds i8, ptr %5, i64 16
  store i64 2, ptr %10, align 8, !tbaa !12
  %11 = tail call fastcc i64 @comb(ptr noundef nonnull byval(%struct.big) align 8 %4, ptr noundef nonnull byval(%struct.big) align 8 %5)
  %12 = tail call i64 @cq_measure_sl(i64 noundef %11) #6
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %5) #6
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %4) #6
  ret i64 %12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i64 @cq_theta_sl(i64 noundef, double noundef) local_unnamed_addr #2

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal fastcc i64 @comb(ptr nocapture noundef readonly byval(%struct.big) align 8 %0, ptr nocapture noundef readonly byval(%struct.big) align 8 %1) unnamed_addr #3 {
  %3 = load i64, ptr %0, align 8, !tbaa !6
  %4 = mul nsw i64 %3, 3
  %5 = getelementptr inbounds i8, ptr %1, i64 8
  %6 = load i64, ptr %5, align 8, !tbaa !11
  %7 = add nsw i64 %4, %6
  %8 = getelementptr inbounds i8, ptr %0, i64 16
  %9 = load i64, ptr %8, align 8, !tbaa !12
  %10 = sub i64 %7, %9
  %11 = getelementptr inbounds i8, ptr %1, i64 16
  %12 = load i64, ptr %11, align 8, !tbaa !12
  %13 = add nsw i64 %10, %12
  ret i64 %13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i64 @ptr_field(i64 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [2 x i32], align 4
  %5 = alloca %struct.R, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #6
  store i32 %2, ptr %4, align 4, !tbaa !13
  %6 = getelementptr inbounds i8, ptr %4, i64 4
  store i32 3, ptr %6, align 4, !tbaa !13
  %7 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %5) #6
  %8 = and i32 %2, 1
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [2 x i32], ptr %4, i64 0, i64 %9
  store ptr %10, ptr %5, align 8, !tbaa !15
  %11 = getelementptr inbounds i8, ptr %5, i64 8
  store i64 %7, ptr %11, align 8, !tbaa !18
  %12 = getelementptr inbounds i8, ptr %5, i64 16
  store i64 5, ptr %12, align 8, !tbaa !19
  %13 = call fastcc i64 @rd(ptr noundef nonnull byval(%struct.R) align 8 %5)
  %14 = call i64 @cq_measure_sl(i64 noundef %13) #6
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %5) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #6
  ret i64 %14
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none) uwtable
define internal fastcc i64 @rd(ptr nocapture noundef readonly byval(%struct.R) align 8 %0) unnamed_addr #4 {
  %2 = load ptr, ptr %0, align 8, !tbaa !15
  %3 = load i32, ptr %2, align 4, !tbaa !13
  %4 = sext i32 %3 to i64
  %5 = getelementptr inbounds i8, ptr %0, i64 8
  %6 = load i64, ptr %5, align 8, !tbaa !18
  %7 = shl nsw i64 %6, 1
  %8 = add nsw i64 %7, %4
  %9 = getelementptr inbounds i8, ptr %0, i64 16
  %10 = load i64, ptr %9, align 8, !tbaa !19
  %11 = add nsw i64 %8, %10
  ret i64 %11
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(read, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !8, i64 0}
!7 = !{!"big", !8, i64 0, !8, i64 8, !8, i64 16}
!8 = !{!"long", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 8}
!12 = !{!7, !8, i64 16}
!13 = !{!14, !14, i64 0}
!14 = !{!"int", !9, i64 0}
!15 = !{!16, !17, i64 0}
!16 = !{!"R", !17, i64 0, !8, i64 8, !8, i64 16}
!17 = !{!"any pointer", !9, i64 0}
!18 = !{!16, !8, i64 8}
!19 = !{!16, !8, i64 16}
; USERCHECK two_rec
; USERCHECK ptr_field
