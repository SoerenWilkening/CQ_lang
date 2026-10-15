; railwindow_accept_dead_temp_borrowed_root.ll — ACCEPT + ADVERSARIAL (bd
; 01po.19 S4 (a)): the borrowed root in the DEAD-TERMINAL driver.
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`).
; In one window the cell is rotated (`cqrt_ry_i32(%L, .3)` on the cell read %L)
; and then read by a dead temporary `x = q + 5` that is itself rotated. The
; spine reverses x per trip (Ry(-.25), add_unc, free) against %L — and must
; STOP at %L: a cell read is a borrowed root (`recoverDataDag`'s window
; frontier), so the cell's own Ry is never collected as a DAG gate,
; never adjointed, and the cell rail is never freed. Pinned: exactly one
; `cqrt_ry_i32(%L, 0.3)`, no negative-angle Ry on %L, and the only free is x's.
; Kill fixture for mutant M1 (window frontier removed from `recoverDataDag`).
;
; SOURCE (clang -O1, verbatim below):
;   /* adversarial (borrowed root in the dead-terminal driver): in ONE window the
;      cell q[i] is rotated and then read by a dead temporary. The temporary's
;      reversal must read the cell rail and never walk into it: walking it would
;      collect the cell's own Ry as a DAG gate and un-rotate the user's cell. */
;   __attribute__((noinline)) int g(int n) {
;     int q[4] = {0};
;     int r = 0;
;     for (int i = 0; i < n; i++) {
;       cq_theta(&q[i & 3], .3);
;       int x = q[i & 3] + 5;
;       cq_theta(&x, .25);
;     }
;     for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;   int main(void) { return g(2); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not='error:' \
; RUN:       --implicit-check-not='cqrt_free(i32 %.rail' --implicit-check-not='double -3.000000e-01'
; S4-LABEL: define {{.*}} @g(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i32(i32 %cq.rail.init)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i32(i32 %.rail, double 3.000000e-01)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %h_op = call i32 @cq_template_add_i32_hl(i32 %.rail, i32 5)
; S4: call void @cqrt_ry_i32(i32 %h_op, double 2.500000e-01)
; S4: call void @cqrt_ry_i32(i32 %h_op, double -2.500000e-01)
; S4: call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %.rail, i32 5)
; S4: call void @cqrt_free(i32 %h_op)
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %m = call i32 @cqrt_measure_i32(i32 %.rail2)
; S4-LABEL: define {{.*}} @main(

; ModuleID = 'deadterm2.c'
source_filename = "deadterm2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %2, i8 0, i64 16, i1 false)
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %5, label %4

4:                                                ; preds = %5, %1
  br label %17

5:                                                ; preds = %1, %5
  %6 = phi i32 [ %14, %5 ], [ 0, %1 ]
  %7 = and i32 %6, 3
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [4 x i32], ptr %2, i64 0, i64 %8
  %10 = load i32, ptr %9, align 4, !tbaa !6
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 3.000000e-01) #6
  store i32 %11, ptr %9, align 4, !tbaa !6
  %12 = add nsw i32 %11, 5
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 2.500000e-01) #6
  %14 = add nuw nsw i32 %6, 1
  %15 = icmp eq i32 %14, %0
  br i1 %15, label %4, label %5, !llvm.loop !10

16:                                               ; preds = %17
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %2) #5
  ret i32 %24

17:                                               ; preds = %4, %17
  %18 = phi i64 [ %25, %17 ], [ 0, %4 ]
  %19 = phi i32 [ %24, %17 ], [ 0, %4 ]
  %20 = shl nsw i32 %19, 1
  %21 = getelementptr inbounds [4 x i32], ptr %2, i64 0, i64 %18
  %22 = load i32, ptr %21, align 4, !tbaa !6
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #5
  %24 = add nsw i32 %23, %20
  %25 = add nuw nsw i64 %18, 1
  %26 = icmp eq i64 %25, 4
  br i1 %26, label %16, label %17, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #4 {
  %1 = tail call i32 @g(i32 noundef 2)
  ret i32 %1
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }

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
