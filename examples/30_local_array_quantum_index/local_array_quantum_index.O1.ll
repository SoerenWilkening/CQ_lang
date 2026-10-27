; ModuleID = 'local_array_quantum_index.c'
source_filename = "local_array_quantum_index.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @local_array_quantum_index(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [4 x i32], align 16    ; C: int arr[4];
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #5    ; C: (arr comes into scope)
  store i32 %2, ptr %5, align 16, !tbaa !6    ; C: arr[0] = a;
  %7 = getelementptr inbounds i8, ptr %5, i64 4    ; C: &arr[1]
  store i32 %3, ptr %7, align 4, !tbaa !6    ; C: arr[1] = b;
  %8 = add nsw i32 %3, %2    ; C: a + b
  %9 = getelementptr inbounds i8, ptr %5, i64 8    ; C: &arr[2]
  store i32 %8, ptr %9, align 8, !tbaa !6    ; C: arr[2] = a + b;
  %10 = mul nsw i32 %3, %2    ; C: a * b
  %11 = getelementptr inbounds i8, ptr %5, i64 12    ; C: &arr[3]
  store i32 %10, ptr %11, align 4, !tbaa !6    ; C: arr[3] = a * b;
  %12 = and i32 %6, 3    ; C: x & 3
  %13 = zext nneg i32 %12 to i64    ; C: x & 3  (as index)
  %14 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %13    ; C: &arr[x & 3]
  %15 = load i32, ptr %14, align 4, !tbaa !6    ; C: int v = arr[x & 3];
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #5    ; C: cq_measure(v)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #5    ; C: (arr goes out of scope)
  ret i32 %16    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @local_array_quantum_write(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16    ; C: int arr[4]
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5    ; C: (arr comes into scope)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)    ; C: = {0, 0, 0, 0};
  %6 = and i32 %5, 3    ; C: x & 3
  %7 = zext nneg i32 %6 to i64    ; C: x & 3  (as index)
  %8 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %7    ; C: &arr[x & 3]
  store i32 %2, ptr %8, align 4, !tbaa !6    ; C: arr[x & 3] = a;
  %9 = load i32, ptr %4, align 16, !tbaa !6    ; C: arr[0]
  %10 = getelementptr inbounds i8, ptr %4, i64 8    ; C: &arr[2]
  %11 = load i32, ptr %10, align 8, !tbaa !6    ; C: arr[2]
  %12 = add nsw i32 %11, %9    ; C: arr[0] + arr[2]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #5    ; C: cq_measure(arr[0] + arr[2])
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5    ; C: (arr goes out of scope)
  ret i32 %13    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
