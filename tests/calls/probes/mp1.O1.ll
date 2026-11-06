; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv2hostres/mp1.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv2hostres/mp1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.memset_pattern = private unnamed_addr constant [4 x i32] [i32 16909060, i32 16909060, i32 16909060, i32 16909060], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @mp1(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #5
  %6 = and i32 %1, 7
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %7
  store i32 %5, ptr %8, align 4, !tbaa !6
  call void asm sideeffect "", "r,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %4) #4, !srcloc !10
  %9 = load i32, ptr %8, align 4, !tbaa !6
  call void @memset_pattern16(ptr nonnull %4, ptr nonnull @.memset_pattern, i64 32), !tbaa !6
  call void asm sideeffect "", "r,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %4) #4, !srcloc !11
  %10 = load i32, ptr %8, align 4, !tbaa !6
  %11 = add nsw i32 %10, %9
  %12 = call i32 @cq_measure_si32(i32 noundef %11) #4
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #4
  ret i32 %12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind willreturn memory(argmem: readwrite)
declare void @memset_pattern16(ptr nocapture writeonly, ptr nocapture readonly, i64) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind willreturn memory(argmem: readwrite) }
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
!10 = !{i64 180}
!11 = !{i64 280}
