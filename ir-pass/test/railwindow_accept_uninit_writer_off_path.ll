; railwindow_accept_uninit_writer_off_path.ll — ACCEPT + ADVERSARIAL (bd 01po.19
; S4, R11 round 2 finding R2-F1). The only classical writer of `q` sits on a
; branch that RETURNS and never reaches the quantization point; the quantum
; path runs the walk on a never-written `q`. Ruling Q1: an object with no
; classical writer on any path TO Q seeds |0>. MEASURED before the fix
; (44c78db4): the writer was counted because it is not dominated by Q, and the
; walk read never-initialized memory (`cqrt_alloc_i32(%cq.rail.init)`). Pinned:
; seed constant 0 and no read of the original object by the walk.
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; ruling
; `ruling-01po19-s4-r1-qs-2026-10-15` Q1).
;
; SOURCE (clang -O1, verbatim below):
;   int main(int argc, char **argv) {
;     int q[4];
;     if (argc > 5) {
;       for (int i = 0; i < argc; i++) q[i & 3] = i;
;       return q[argc & 3];
;     }
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], 0.5);
;     int s = 0;
;     for (int i = 0; i < 4; i++) s += cq_measure(q[i]);
;     return s;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not='error:' --implicit-check-not=cqrt_free --implicit-check-not=cq.rail.init
; S4-LABEL: define {{.*}} @main(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i32(i32 0)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i32(i32 %.rail, double 5.000000e-01)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %m = call i32 @cqrt_measure_i32(i32 %.rail2)

; ModuleID = 'writer_off_path.c'
source_filename = "writer_off_path.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #3
  %4 = icmp sgt i32 %0, 5
  br i1 %4, label %10, label %17

5:                                                ; preds = %10
  %6 = and i32 %0, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %7
  %9 = load i32, ptr %8, align 4, !tbaa !6
  br label %33

10:                                               ; preds = %2, %10
  %11 = phi i32 [ %15, %10 ], [ 0, %2 ]
  %12 = and i32 %11, 3
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %13
  store i32 %11, ptr %14, align 4, !tbaa !6
  %15 = add nuw nsw i32 %11, 1
  %16 = icmp eq i32 %15, %0
  br i1 %16, label %5, label %10, !llvm.loop !10

17:                                               ; preds = %2, %17
  %18 = phi i64 [ %22, %17 ], [ 0, %2 ]
  %19 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !6
  %21 = tail call i32 @cq_theta_si32(i32 noundef %20, double noundef 5.000000e-01) #4
  store i32 %21, ptr %19, align 4, !tbaa !6
  %22 = add nuw nsw i64 %18, 1
  %23 = icmp eq i64 %22, 4
  br i1 %23, label %24, label %17, !llvm.loop !13

24:                                               ; preds = %17, %24
  %25 = phi i64 [ %31, %24 ], [ 0, %17 ]
  %26 = phi i32 [ %30, %24 ], [ 0, %17 ]
  %27 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %25
  %28 = load i32, ptr %27, align 4, !tbaa !6
  %29 = tail call i32 @cq_measure_si32(i32 noundef %28) #3
  %30 = add nsw i32 %29, %26
  %31 = add nuw nsw i64 %25, 1
  %32 = icmp eq i64 %31, 4
  br i1 %32, label %33, label %24, !llvm.loop !14

33:                                               ; preds = %24, %5
  %34 = phi i32 [ %9, %5 ], [ %30, %24 ]
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #3
  ret i32 %34
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

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
!14 = distinct !{!14, !11, !12}
