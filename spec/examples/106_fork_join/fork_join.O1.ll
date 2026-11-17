; ModuleID = 'fork_join.c'
source_filename = "fork_join.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.job = type { i32, i32 }
%struct._opaque_pthread_mutex_t = type { i64, [56 x i8] }

; Function Attrs: nounwind ssp uwtable
define i32 @fork_join(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca %struct.job, align 4    ; C: struct job a
  %5 = alloca %struct.job, align 4    ; C: struct job b
  %6 = alloca ptr, align 8    ; C: pthread_t ta
  %7 = alloca ptr, align 8    ; C: pthread_t tb
  %8 = alloca %struct._opaque_pthread_mutex_t, align 8    ; C: pthread_mutex_t m
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #6    ; C: (a comes into scope)
  store i32 %9, ptr %4, align 4, !tbaa !6    ; C: a.in = x
  %10 = getelementptr inbounds i8, ptr %4, i64 4    ; C: &a.out
  store i32 0, ptr %10, align 4, !tbaa !11    ; C: a.out = 0
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #6    ; C: (b comes into scope)
  store i32 %2, ptr %5, align 4, !tbaa !6    ; C: b.in = c
  %11 = getelementptr inbounds i8, ptr %5, i64 4    ; C: &b.out
  store i32 0, ptr %11, align 4, !tbaa !11    ; C: b.out = 0
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #6    ; C: (ta comes into scope)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #6    ; C: (tb comes into scope)
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %8) #6    ; C: (m comes into scope)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(64) %8, i8 0, i64 64, i1 false)    ; C: m = PTHREAD_MUTEX_INITIALIZER
  store i64 850045863, ptr %8, align 8    ; C: m = PTHREAD_MUTEX_INITIALIZER (signature word)
  %12 = call i32 @pthread_create(ptr noundef nonnull %6, ptr noundef null, ptr noundef nonnull @worker, ptr noundef nonnull %4) #6    ; C: pthread_create(&ta, 0, worker, &a);
  %13 = call i32 @pthread_create(ptr noundef nonnull %7, ptr noundef null, ptr noundef nonnull @worker, ptr noundef nonnull %5) #6    ; C: pthread_create(&tb, 0, worker, &b);
  %14 = load ptr, ptr %6, align 8, !tbaa !12    ; C: ta
  %15 = call i32 @"\01_pthread_join"(ptr noundef %14, ptr noundef null) #6    ; C: pthread_join(ta, 0);
  %16 = load ptr, ptr %7, align 8, !tbaa !12    ; C: tb
  %17 = call i32 @"\01_pthread_join"(ptr noundef %16, ptr noundef null) #6    ; C: pthread_join(tb, 0);
  %18 = call i32 @pthread_mutex_lock(ptr noundef nonnull %8) #6    ; C: pthread_mutex_lock(&m);
  %19 = load i32, ptr %10, align 4, !tbaa !11    ; C: a.out
  %20 = load i32, ptr %11, align 4, !tbaa !11    ; C: b.out
  %21 = add nsw i32 %20, %19    ; C: int s = a.out + b.out;
  %22 = call i32 @pthread_mutex_unlock(ptr noundef nonnull %8) #6    ; C: pthread_mutex_unlock(&m);
  %23 = call i32 @cq_measure_si32(i32 noundef %21) #6    ; C: cq_measure(s)
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %8) #6    ; C: (m goes out of scope)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #6    ; C: (tb goes out of scope)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #6    ; C: (ta goes out of scope)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #6    ; C: (b goes out of scope)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #6    ; C: (a goes out of scope)
  ret i32 %23    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare i32 @pthread_create(ptr noundef, ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal noalias noundef ptr @worker(ptr nocapture noundef %0) #4 {
  %2 = load i32, ptr %0, align 4, !tbaa !6    ; C: j->in
  %3 = mul nsw i32 %2, %2    ; C: j->in * j->in
  %4 = add nuw nsw i32 %3, 1    ; C: j->in * j->in + 1
  %5 = getelementptr inbounds i8, ptr %0, i64 4    ; C: &j->out
  store i32 %4, ptr %5, align 4, !tbaa !11    ; C: j->out = ...;
  ret ptr null    ; C: return 0
}

declare i32 @"\01_pthread_join"(ptr noundef, ptr noundef) local_unnamed_addr #2

declare i32 @pthread_mutex_lock(ptr noundef) local_unnamed_addr #2

declare i32 @pthread_mutex_unlock(ptr noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"job", !8, i64 0, !8, i64 4}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 4}
!12 = !{!13, !13, i64 0}
!13 = !{!"any pointer", !9, i64 0}
