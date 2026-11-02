; Rule 22 (cq-k65d): a run-time-length memcpy between QRAMs of different element sizes (bytes into {i32, i16}
; elements): one trip per lcm of the element sizes. cqcheck user (32 samples): PASS.
; CHECK lp_qq: call i32 @cqrt_qram_load_i8_hl(
; CHECK lp_qq: call void @cqrt_qram_store_i16_hl_controlled(
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

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @lp_qq(i32 noundef %0, double noundef %1, i64 noundef %2) local_unnamed_addr #3 {
  %4 = alloca [3 x %struct.S], align 16
  %5 = alloca [24 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %4) #4
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %4, ptr noundef nonnull align 16 dereferenceable(24) @__const.lp_qq.s, i64 24, i1 false)
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %5) #4
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %5, ptr noundef nonnull align 16 dereferenceable(24) @__const.lp_qq.b, i64 24, i1 false)
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %7 = urem i32 %6, 3
  %8 = mul nuw nsw i32 %7, 5
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [24 x i8], ptr %5, i64 0, i64 %9
  store i8 99, ptr %10, align 1, !tbaa !6
  %11 = zext nneg i32 %7 to i64
  %12 = getelementptr inbounds [3 x %struct.S], ptr %4, i64 0, i64 %11
  store i32 4, ptr %12, align 8, !tbaa !9
  %13 = urem i64 %2, 25
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 16 %4, ptr nonnull align 16 %5, i64 %13, i1 false)
  %14 = load i32, ptr %12, align 8, !tbaa !9
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #4
  %16 = getelementptr inbounds i8, ptr %12, i64 4
  %17 = load i16, ptr %16, align 4, !tbaa !13
  %18 = tail call signext i16 @cq_measure_si16(i16 noundef signext %17) #4
  %19 = sext i16 %18 to i32
  %20 = add nsw i32 %15, %19
  %21 = getelementptr inbounds i8, ptr %4, i64 8
  %22 = load i32, ptr %21, align 8, !tbaa !9
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #4
  %24 = add nsw i32 %20, %23
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %5) #4
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %4) #4
  ret i32 %24
}

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
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10, !11, i64 0}
!10 = !{!"", !11, i64 0, !12, i64 4}
!11 = !{!"int", !7, i64 0}
!12 = !{!"short", !7, i64 0}
!13 = !{!10, !12, i64 4}
