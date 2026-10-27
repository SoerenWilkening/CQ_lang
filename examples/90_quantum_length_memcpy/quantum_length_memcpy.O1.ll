; ModuleID = 'quantum_length_memcpy.c'
source_filename = "quantum_length_memcpy.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @memcpy_quantum_len(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4    ; C: unsigned char d[4]
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4)    ; C: (d comes into scope)
  store i32 151587081, ptr %4, align 4    ; C: d = {9, 9, 9, 9}
  %6 = and i32 %5, 3    ; C: x & 3
  %7 = zext nneg i32 %6 to i64    ; C: (the length)
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 4 %4, ptr align 1 %2, i64 %7, i1 false)    ; C: memcpy(d, src, x & 3);
  %8 = lshr i32 %5, 2    ; C: x >> 2
  %9 = and i32 %8, 3    ; C: (x >> 2) & 3
  %10 = zext nneg i32 %9 to i64    ; C: (the length)
  call void @llvm.memset.p0.i64(ptr nonnull align 4 %4, i8 0, i64 %10, i1 false)    ; C: memset(d, 0, (x >> 2) & 3);
  %11 = load i8, ptr %4, align 4, !tbaa !6    ; C: d[0]
  %12 = zext i8 %11 to i32    ; C: (int)d[0]
  %13 = getelementptr inbounds i8, ptr %4, i64 3    ; C: &d[3]
  %14 = load i8, ptr %13, align 1, !tbaa !6    ; C: d[3]
  %15 = zext i8 %14 to i32    ; C: (int)d[3]
  %16 = add nuw nsw i32 %15, %12    ; C: d[0] + d[3]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #6    ; C: cq_measure(d[0] + d[3])
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4)    ; C: (d goes out of scope)
  ret i32 %17    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @memcpy_quantum_src(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, ptr nocapture noundef readonly %3) local_unnamed_addr #0 {
  %5 = alloca i16, align 2    ; C: unsigned char d[2]
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %5)    ; C: (d comes into scope)
  store i16 2313, ptr %5, align 2    ; C: d = {9, 9}
  %7 = and i32 %6, 1    ; C: x & 1
  %8 = icmp eq i32 %7, 0    ; C: (x & 1) ? ... : ...
  %9 = select i1 %8, ptr %3, ptr %2    ; C: const unsigned char *s = (x & 1) ? s1 : s2;
  %10 = select i1 %8, i64 1, i64 2    ; C: x & 1 ? 2 : 1
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 2 dereferenceable(1) %5, ptr noundef nonnull align 1 dereferenceable(1) %9, i64 %10, i1 false)    ; C: memcpy(d, s, x & 1 ? 2 : 1);
  %11 = load i8, ptr %5, align 2, !tbaa !6    ; C: d[0]
  %12 = zext i8 %11 to i32    ; C: (int)d[0]
  %13 = getelementptr inbounds i8, ptr %5, i64 1    ; C: &d[1]
  %14 = load i8, ptr %13, align 1, !tbaa !6    ; C: d[1]
  %15 = zext i8 %14 to i32    ; C: (int)d[1]
  %16 = add nuw nsw i32 %15, %12    ; C: d[0] + d[1]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #6    ; C: cq_measure(d[0] + d[1])
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %5)    ; C: (d goes out of scope)
  ret i32 %17    ; C: return
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
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
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
