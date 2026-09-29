; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = alloca [2 x i32], align 4
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  %5 = load ptr, ptr %4, align 8, !tbaa !6
  %6 = tail call i32 @atoi(ptr nocapture noundef %5)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #4
  %7 = and i32 %6, 7
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 5.000000e-01) #4
  store i32 %8, ptr %3, align 4, !tbaa !10
  %9 = getelementptr inbounds i8, ptr %3, i64 4
  store i32 %6, ptr %9, align 4, !tbaa !10
  %10 = mul nsw i32 %8, 3
  %11 = xor i32 %10, %8
  %12 = call i32 @h(i32 noundef %6, i32 noundef %8, ptr noundef nonnull %3) #4
  %13 = icmp eq i32 %11, 10
  br i1 %13, label %14, label %15

14:                                               ; preds = %2
  call void @cq_phi(double noundef 3.141590e+00) #4
  br label %15

15:                                               ; preds = %14, %2
  %16 = call i32 @cq_measure_si32(i32 noundef %12) #4
  %17 = call i32 @cq_theta_si32(i32 noundef %8, double noundef 0x3FE6666666666666) #4
  %18 = call i32 @cq_measure_si32(i32 noundef %17) #4
  %19 = add nsw i32 %18, %16
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #4
  ret i32 %19
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare void @cq_phi(double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1, ptr nocapture noundef %2) local_unnamed_addr #0 {
  %4 = load i32, ptr %2, align 4, !tbaa !10
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 3.000000e-01) #4
  store i32 %5, ptr %2, align 4, !tbaa !10
  %6 = add nsw i32 %1, 1
  ret i32 %6
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
