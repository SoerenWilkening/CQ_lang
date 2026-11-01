; ModuleID = 'ptr_cell_interior.c'
source_filename = "ptr_cell_interior.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%union.pl = type { ptr }

; Function Attrs: nounwind ssp uwtable
define i32 @pc_interior(i32 noundef %0, double noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [3 x i64], align 16
  %5 = alloca [3 x i64], align 16
  %6 = alloca %union.pl, align 8
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %4) #5
  store i64 %2, ptr %4, align 16, !tbaa !6
  %8 = getelementptr inbounds i8, ptr %4, i64 8
  %9 = shl nsw i64 %2, 1
  store i64 %9, ptr %8, align 8, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %4, i64 16
  store i64 3, ptr %10, align 16, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %5) #5
  store i64 5, ptr %5, align 16, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %5, i64 8
  store i64 6, ptr %11, align 8, !tbaa !6
  %12 = getelementptr inbounds i8, ptr %5, i64 16
  %13 = sub nsw i64 0, %2
  store i64 %13, ptr %12, align 16, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #5
  %14 = and i32 %7, 1
  %15 = icmp eq i32 %14, 0
  %16 = select i1 %15, ptr %12, ptr %10
  store ptr %16, ptr %6, align 8, !tbaa !10
  call fastcc void @back(ptr noundef nonnull %6)
  %17 = load ptr, ptr %6, align 8, !tbaa !10
  %18 = load i64, ptr %17, align 8, !tbaa !6
  %19 = trunc i64 %18 to i32
  %20 = call i32 @cq_measure_si32(i32 noundef %19) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #5
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %5) #5
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %4) #5
  ret i32 %20
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @back(ptr nocapture noundef %0) unnamed_addr #3 {
  %2 = load i64, ptr %0, align 8, !tbaa !10
  %3 = add i64 %2, -8
  store i64 %3, ptr %0, align 8, !tbaa !10
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"long", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!8, !8, i64 0}
