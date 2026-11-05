; ModuleID = 'tests/eff-conc/probes/conc_tls.c'
source_filename = "tests/eff-conc/probes/conc_tls.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct._opaque_pthread_mutex_t = type { i64, [56 x i8] }

@tcell = thread_local local_unnamed_addr global i32 3, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @p_tls(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %5 = tail call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @tcell)
  %6 = add nsw i32 %4, %2
  store i32 %6, ptr %5, align 4
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #5
  ret i32 %7
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare nonnull ptr @llvm.threadlocal.address.p0(ptr nonnull) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_mutex_init(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca %struct._opaque_pthread_mutex_t, align 8
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %3) #5
  %5 = call i32 @pthread_mutex_init(ptr noundef nonnull %3, ptr noundef null) #5
  %6 = call i32 @pthread_mutex_lock(ptr noundef nonnull %3) #5
  %7 = add nsw i32 %4, 1
  %8 = call i32 @pthread_mutex_unlock(ptr noundef nonnull %3) #5
  %9 = call i32 @pthread_mutex_destroy(ptr noundef nonnull %3) #5
  %10 = call i32 @cq_measure_si32(i32 noundef %7) #5
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %3) #5
  ret i32 %10
}

declare i32 @pthread_mutex_init(ptr noundef, ptr noundef) local_unnamed_addr #2

declare i32 @pthread_mutex_lock(ptr noundef) local_unnamed_addr #2

declare i32 @pthread_mutex_unlock(ptr noundef) local_unnamed_addr #2

declare i32 @pthread_mutex_destroy(ptr noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
