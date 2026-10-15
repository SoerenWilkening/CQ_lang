; railwindow_accept_partial_init_keeps_memory.ll — ACCEPT (bd 01po.19 S4, R11
; round 2, the twin of railwindow_accept_uninit_writer_off_path.ll). The
; classical writer `q[argc&3] = 7` lies on SOME paths to Q: the object is
; partially initialized, the ruled "keep the memory value" class, so the walk
; copies every cell from the original object (`cqrt_alloc_i32(%cq.rail.init)`),
; written or not.
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; ruling
; `ruling-01po19-s4-r1-qs-2026-10-15` Q1).
;
; SOURCE (clang -O1, verbatim below):
;   /* bd 01po.19 S4 R11 round 2: a classical writer on SOME paths to Q -- the
;      ruled "partially initialized: keep memory" class (ruling Q1). */
;   int main(int argc, char **argv) {
;     int q[4];
;     if (argc > 5) q[argc & 3] = 7;
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], 0.5);
;     int s = 0;
;     for (int i = 0; i < 4; i++) s += cq_measure(q[i]);
;     return s;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not='error:' --implicit-check-not=cqrt_free
; S4-LABEL: define {{.*}} @main(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i32(i32 %cq.rail.init)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i32(i32 %.rail, double 5.000000e-01)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %m = call i32 @cqrt_measure_i32(i32 %.rail2)

; ModuleID = 'some_paths.c'
source_filename = "some_paths.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #3
  %4 = icmp sgt i32 %0, 5
  br i1 %4, label %5, label %9

5:                                                ; preds = %2
  %6 = and i32 %0, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %7
  store i32 7, ptr %8, align 4, !tbaa !6
  br label %9

9:                                                ; preds = %5, %2
  br label %10

10:                                               ; preds = %9, %10
  %11 = phi i64 [ %15, %10 ], [ 0, %9 ]
  %12 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4, !tbaa !6
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 5.000000e-01) #4
  store i32 %14, ptr %12, align 4, !tbaa !6
  %15 = add nuw nsw i64 %11, 1
  %16 = icmp eq i64 %15, 4
  br i1 %16, label %18, label %10, !llvm.loop !10

17:                                               ; preds = %18
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #3
  ret i32 %24

18:                                               ; preds = %10, %18
  %19 = phi i64 [ %25, %18 ], [ 0, %10 ]
  %20 = phi i32 [ %24, %18 ], [ 0, %10 ]
  %21 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %19
  %22 = load i32, ptr %21, align 4, !tbaa !6
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #3
  %24 = add nsw i32 %23, %20
  %25 = add nuw nsw i64 %19, 1
  %26 = icmp eq i64 %25, 4
  br i1 %26, label %17, label %18, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
