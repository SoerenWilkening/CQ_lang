; Rule 22: a quantum-length memcpy from a quantum source pointer whose length is not a select on the
; source's own condition: the length's bound per source object is not derived (a bound valid for every
; object would speculate host bytes past one), so it is unimplemented.
; EXPECT-ERROR: mem-qram: a quantum-length memcpy/memmove from a quantum source pointer whose length is not selected with it
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #0

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nounwind ssp uwtable
define i32 @fat_src_len_apart(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, ptr nocapture noundef readonly %3) local_unnamed_addr #3 {
  %5 = alloca i64, align 8
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5)
  store i32 9, ptr %5, align 8
  %7 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 %0, ptr %7, align 4
  %8 = and i32 %6, 1
  %9 = icmp eq i32 %8, 0
  %10 = select i1 %9, ptr %3, ptr %2
  %11 = and i32 %6, 2
  %12 = icmp eq i32 %11, 0
  %13 = select i1 %12, i64 4, i64 8
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(4) %5, ptr noundef nonnull align 4 dereferenceable(4) %10, i64 %13, i1 false)
  %14 = load i32, ptr %5, align 8
  %15 = getelementptr inbounds i8, ptr %5, i64 4
  %16 = load i32, ptr %15, align 4
  %17 = add nsw i32 %16, %14
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5)
  ret i32 %18
}

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }


!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
