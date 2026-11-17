; ModuleID = 'bus_quantum_address.c'
source_filename = "bus_quantum_address.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.bus_quantum_address.a = private unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @bus_quantum_address(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = alloca [4 x i32], align 16    ; C: int a[4]
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&k, tk);
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %2, double noundef %3) #4    ; C: cq_theta(&j, tj);
  %10 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %5) #4    ; C: cq_theta(&x, tx);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %7) #5    ; C: (a comes into scope)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %7, ptr noundef nonnull align 16 dereferenceable(16) @__const.bus_quantum_address.a, i64 16, i1 false)    ; C: a = {1, 2, 3, 4}
  %11 = and i32 %8, 3    ; C: k & 3
  %12 = zext nneg i32 %11 to i64    ; C: (index)
  %13 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %12    ; C: &a[k & 3]
  store i32 %10, ptr %13, align 4, !tbaa !6    ; C: a[k & 3] = x;
  %14 = and i32 %9, 3    ; C: j & 3
  %15 = zext nneg i32 %14 to i64    ; C: (index)
  %16 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %15    ; C: &a[j & 3]
  %17 = load i32, ptr %16, align 4, !tbaa !6    ; C: int r = a[j & 3];
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #5    ; C: cq_measure(r)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %7) #5    ; C: (a goes out of scope)
  ret i32 %18    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
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
