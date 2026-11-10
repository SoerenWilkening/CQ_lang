; ModuleID = 'q9.c'
source_filename = "q9.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define range(i32 0, 256) i32 @rd(ptr nocapture noundef readonly %0) local_unnamed_addr #0 {
  %2 = load i8, ptr %0, align 1, !tbaa !6
  %3 = zext i8 %2 to i32
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @q9(i32 noundef %0) local_unnamed_addr #1 {
  %2 = alloca [8192 x i8], align 16
  %3 = alloca [8192 x i8], align 16
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #6
  %5 = and i32 %4, 8190
  %6 = or disjoint i32 %5, 1
  call void @llvm.lifetime.start.p0(i64 8192, ptr nonnull %2) #7
  call void @llvm.lifetime.start.p0(i64 8192, ptr nonnull %3) #7
  %7 = zext nneg i32 %6 to i64
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(1) %2, i8 7, i64 %7, i1 false)
  %8 = trunc i32 %4 to i8
  store i8 %8, ptr %2, align 16, !tbaa !6
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(1) %3, ptr noundef nonnull align 16 dereferenceable(1) %2, i64 %7, i1 false)
  %9 = call i32 @rd(ptr noundef nonnull %2)
  %10 = call i32 @rd(ptr noundef nonnull %3)
  %11 = add nuw nsw i32 %10, %9
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #7
  call void @llvm.lifetime.end.p0(i64 8192, ptr nonnull %3) #7
  call void @llvm.lifetime.end.p0(i64 8192, ptr nonnull %2) #7
  ret i32 %12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #4

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #5

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #5 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
