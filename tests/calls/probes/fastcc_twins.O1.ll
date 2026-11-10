; ModuleID = 'tests/calls/probes/fastcc_twins.c'
source_filename = "tests/calls/probes/fastcc_twins.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @e(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i32], align 16
  %3 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 5.000000e-01) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %2) #6
  store i32 %0, ptr %2, align 16, !tbaa !6
  %4 = getelementptr inbounds i8, ptr %2, i64 4
  store i32 3, ptr %4, align 4, !tbaa !6
  %5 = getelementptr inbounds i8, ptr %2, i64 8
  %6 = add nsw i32 %0, 1
  store i32 %6, ptr %5, align 8, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %2, i64 12
  store i32 7, ptr %7, align 4, !tbaa !6
  %8 = sext i8 %3 to i32
  %9 = tail call fastcc i32 @h(i32 noundef %8, i32 noundef %0)
  %10 = and i32 %8, 1
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %18, label %12

12:                                               ; preds = %1
  %13 = tail call fastcc i32 @h(i32 noundef %9, i32 noundef %8)
  %14 = tail call fastcc i32 @g(i32 noundef %8)
  %15 = add nsw i32 %14, %13
  %16 = call fastcc i32 @w(ptr noundef nonnull %2, i32 noundef %9)
  %17 = add nsw i32 %15, %16
  br label %18

18:                                               ; preds = %12, %1
  %19 = phi i32 [ %17, %12 ], [ 0, %1 ]
  %20 = mul nsw i32 %19, %9
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #6
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %2) #6
  ret i32 %21
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc i32 @h(i32 noundef %0, i32 noundef %1) unnamed_addr #3 {
  %3 = mul nsw i32 %1, %0
  %4 = xor i32 %1, %0
  %5 = add nsw i32 %3, %4
  ret i32 %5
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc range(i32 -2147483648, 2147483645) i32 @g(i32 noundef %0) unnamed_addr #3 {
  %2 = add nsw i32 %0, 1
  %3 = tail call fastcc i32 @h(i32 noundef %0, i32 noundef %2)
  %4 = add nsw i32 %3, -3
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal fastcc i32 @w(ptr nocapture noundef readonly %0, i32 noundef %1) unnamed_addr #4 {
  %3 = and i32 %1, 3
  %4 = zext nneg i32 %3 to i64
  %5 = getelementptr inbounds i32, ptr %0, i64 %4
  %6 = load i32, ptr %5, align 4, !tbaa !6
  %7 = xor i32 %6, %1
  ret i32 %7
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
