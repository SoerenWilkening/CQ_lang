; ModuleID = 'struct_array_quantum_index_rmw.c'
source_filename = "struct_array_quantum_index_rmw.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.cell = type { i32, i32 }

@__const.struct_array_quantum_index_rmw.arr = private unnamed_addr constant [4 x %struct.cell] [%struct.cell { i32 1, i32 2 }, %struct.cell { i32 3, i32 4 }, %struct.cell { i32 5, i32 6 }, %struct.cell { i32 7, i32 8 }], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @struct_array_quantum_index_rmw(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x %struct.cell], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #4
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %4, ptr noundef nonnull align 16 dereferenceable(32) @__const.struct_array_quantum_index_rmw.arr, i64 32, i1 false)
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %6 = and i32 %5, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [4 x %struct.cell], ptr %4, i64 0, i64 %7
  %9 = load i32, ptr %8, align 8, !tbaa !6
  %10 = add nsw i32 %9, %2
  store i32 %10, ptr %8, align 8, !tbaa !6
  %11 = add i32 %5, 1
  %12 = and i32 %11, 3
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [4 x %struct.cell], ptr %4, i64 0, i64 %13, i32 1
  store i32 %10, ptr %14, align 4, !tbaa !11
  %15 = xor i32 %6, 2
  %16 = zext nneg i32 %15 to i64
  %17 = getelementptr inbounds [4 x %struct.cell], ptr %4, i64 0, i64 %16
  %18 = load i32, ptr %17, align 8, !tbaa !6
  %19 = add nsw i32 %18, %10
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #4
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #4
  ret i32 %20
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !8, i64 0}
!7 = !{!"cell", !8, i64 0, !8, i64 4}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 4}
