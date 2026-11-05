; ModuleID = 'tests/eff-conc/probes/vol_rail.c'
source_filename = "tests/eff-conc/probes/vol_rail.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@vtab = global [4 x i32] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define void @p_vol_rail_store(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = and i32 %0, 3
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %1) #3
  %6 = and i32 %5, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [4 x i32], ptr @vtab, i64 0, i64 %7
  store volatile i32 %2, ptr %8, align 4
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_vol_rail_load(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = and i32 %0, 3
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %1) #3
  %5 = and i32 %4, 3
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [4 x i32], ptr @vtab, i64 0, i64 %6
  %8 = load volatile i32, ptr %7, align 4
  %9 = add nsw i32 %8, %4
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  ret i32 %10
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @p_vol_local_rail(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [2 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #4
  store volatile i32 %2, ptr %4, align 4
  %5 = add nsw i32 %2, 1
  %6 = getelementptr inbounds i8, ptr %4, i64 4
  store volatile i32 %5, ptr %6, align 4
  %7 = and i32 %0, 1
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef %1) #3
  %9 = and i32 %8, 1
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [2 x i32], ptr %4, i64 0, i64 %10
  store volatile i32 9, ptr %11, align 4
  %12 = tail call i32 @cq_measure_si32(i32 noundef %8) #4
  %13 = load volatile i32, ptr %4, align 4
  %14 = add nsw i32 %13, %12
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #4
  ret i32 %14
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
