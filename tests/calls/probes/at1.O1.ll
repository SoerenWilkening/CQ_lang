; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv2hostres/at1.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv2hostres/at1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.B = type { i64, i64, i64 }

@g = global %struct.B zeroinitializer, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @at1(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca %struct.B, align 8
  %4 = alloca %struct.B, align 8
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %3) #5
  %6 = sext i32 %5 to i64
  store i64 %6, ptr %3, align 8, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %3, i64 8
  store i64 1, ptr %7, align 8, !tbaa !11
  %8 = getelementptr inbounds i8, ptr %3, i64 16
  store i64 2, ptr %8, align 8, !tbaa !12
  call void @__atomic_store(i64 noundef 24, ptr noundef nonnull @g, ptr noundef nonnull %3, i32 noundef 5)
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %4) #5
  call void @__atomic_load(i64 noundef 24, ptr noundef nonnull @g, ptr noundef nonnull %4, i32 noundef 5)
  %9 = load i64, ptr %4, align 8, !tbaa !6
  %10 = trunc i64 %9 to i32
  %11 = add nsw i32 %10, 1
  %12 = call i32 @cq_measure_si32(i32 noundef %11) #5
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %4) #5
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %3) #5
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nofree nounwind willreturn
declare void @__atomic_store(i64, ptr, ptr, i32) local_unnamed_addr #3

; Function Attrs: mustprogress nofree nounwind willreturn
declare void @__atomic_load(i64, ptr, ptr, i32) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn }
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
!6 = !{!7, !8, i64 0}
!7 = !{!"B", !8, i64 0, !8, i64 8, !8, i64 16}
!8 = !{!"long", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 8}
!12 = !{!7, !8, i64 16}
