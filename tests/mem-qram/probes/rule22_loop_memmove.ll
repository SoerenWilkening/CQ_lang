; Rule 22 (cq-k65d): a run-time-length memmove inside one QRAM: through a temporary byte QRAM sized by the length
; (every source byte read before any store), both passes reversed by one deferred item. cqcheck user (30 samples): PASS.
; CHECK lp_move: call i32 @cqrt_qram_alloc_i8(
; CHECK lp_move: call void @cqrt_qram_store_i8_hl_controlled(
; CHECK-COUNT lp_move: call void @cqrt_qram_store_i16_hl_controlled( 1
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.S = type { i32, i16 }

@__const.lp_move.a = hidden unnamed_addr constant [10 x i16] [i16 1, i16 2, i16 3, i16 4, i16 5, i16 6, i16 7, i16 8, i16 9, i16 10], align 16
@__const.lp_qq.s = hidden unnamed_addr constant [3 x %struct.S] [%struct.S { i32 -1, i16 -2 }, %struct.S { i32 -1, i16 -2 }, %struct.S { i32 -1, i16 -2 }], align 16
@__const.lp_qq.b = hidden unnamed_addr constant [24 x i8] c"\00\07\0E\15\1C#*18?FMT[bipw~\85\8C\93\9A\A1", align 16

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #0

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nounwind ssp uwtable
define range(i32 -3342336, 3342235) i32 @lp_move(i32 noundef %0, double noundef %1, i64 noundef %2, i64 noundef %3) local_unnamed_addr #3 {
  %5 = alloca [10 x i16], align 16
  call void @llvm.lifetime.start.p0(i64 20, ptr nonnull %5) #4
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(20) %5, ptr noundef nonnull align 16 dereferenceable(20) @__const.lp_move.a, i64 20, i1 false)
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %7 = urem i32 %6, 10
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [10 x i16], ptr %5, i64 0, i64 %8
  store i16 77, ptr %9, align 2, !tbaa !6
  %10 = urem i64 %2, 5
  %11 = urem i64 %3, 5
  %12 = getelementptr inbounds i16, ptr %5, i64 %11
  %13 = getelementptr inbounds i8, ptr %5, i64 4
  %14 = shl nuw nsw i64 %10, 1
  call void @llvm.memmove.p0.p0.i64(ptr nonnull align 2 %12, ptr nonnull align 4 %13, i64 %14, i1 false)
  %15 = load i16, ptr %9, align 2, !tbaa !6
  %16 = tail call signext i16 @cq_measure_si16(i16 noundef signext %15) #4
  %17 = sext i16 %16 to i32
  %18 = getelementptr inbounds i8, ptr %5, i64 6
  %19 = load i16, ptr %18, align 2, !tbaa !6
  %20 = tail call signext i16 @cq_measure_si16(i16 noundef signext %19) #4
  %21 = sext i16 %20 to i32
  %22 = mul nsw i32 %21, 100
  %23 = add nsw i32 %22, %17
  %24 = getelementptr inbounds i8, ptr %5, i64 8
  %25 = load i16, ptr %24, align 8, !tbaa !6
  %26 = tail call signext i16 @cq_measure_si16(i16 noundef signext %25) #4
  %27 = sext i16 %26 to i32
  %28 = add nsw i32 %23, %27
  call void @llvm.lifetime.end.p0(i64 20, ptr nonnull %5) #4
  ret i32 %28
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memmove.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i1 immarg) #2

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #1

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"short", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
