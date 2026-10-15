; railwindow_ghz_cnot_walk_accept.ll — ACCEPT (bd `test_C_libtooling-01po.19`
; S5; was railwindow_ghz_cnot_walk_pending.ll, which declined "needs S5").
;
; GHZ as a CNOT walk `q[i+1] ^= q[i]` over a `_Bool` array. -O1 carries q[i]
; across the back edge in a header φ (`phi i8 [zext θ, pre], [zext (icmp ne),
; latch]`); design Q6 (a), deferred by S3 and built in S5
; (RailWindowPhiUndo.cpp), maps it back to a load of cell i by SCEV identity.
; The update `icmp ne (zext q[i+1]), (zext q[i])` is the `_Bool` spelling of an
; i1 xor (interface (a), `boolCompareXor`); its old operand q[i+1] is a cell
; read whose cell receives the result (interface (b), `railWindowWritesBack`),
; reloaded every trip (`railWindowSameTripTarget`), so dm7f.51's quantum-source
; round lowers it IN PLACE: `cqrt_cnot(q[i], q[i+1])`, the store a self-store.
; Neither the out-of-place `cq_template_xor` (r2j3.33) nor a dead `zext` copy
; template of the undone φ's incomings (a dirty entangled rail) may appear.
;
; ANALYTIC READING of the pinned stream: Ry(π/2) on h (cell 0's rail, the
; rebind of the |0> rail the walk at Q minted) gives (|0>+|1>)/√2; trip 0 is
; CNOT(cell0 -> cell1), trip 1 CNOT(cell1 -> cell2); the measure walk reads the
; three cell rails: (|000> + |111>)/√2, P = 1/2 each (scratch state-vector
; propagation of the e2e trace, 2026-10-15). No cqrt_free (R5).
;
; SOURCE (clang -O1, verbatim below):
;   /* GHZ over a bool array: q[i+1] ^= q[i] is a CNOT chain written as an array walk
;      with a straight-line store outside it (two store sites). */
;   int main(void) {
;     bool q[3] = {0};
;     cq_theta(&q[0], 1.5707963267948966);
;     for (int i = 0; i < 2; i++) q[i + 1] ^= q[i];
;     int r = 0;
;     for (int i = 0; i < 3; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='error:' --implicit-check-not=cqrt_free \
; RUN:       --implicit-check-not=cq_template_ --implicit-check-not='phi i8' \
; RUN:       --implicit-check-not='call void @cqrt_cnot'
; CHECK-LABEL: define i32 @main(
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h, double 0x3FF921FB54442D18)
; CHECK: store i32 %h, ptr %.rails, align 4
; CHECK: %cq.cell.addr = getelementptr i32, ptr %.rails, i64 [[I:%[0-9]+]]
; CHECK-NEXT: %.cell = load i32, ptr %cq.cell.addr, align 4
; CHECK-NEXT: [[I1:%[0-9]+]] = add nuw nsw i64 [[I]], 1
; CHECK-NEXT: %cq.rail.addr = getelementptr i32, ptr %.rails, i64 [[I1]]
; CHECK-NEXT: %.rail = load i32, ptr %cq.rail.addr, align 4
; CHECK-NEXT: call void @cqrt_cnot(i32 %.cell, i32 %.rail), !cq.inplace.qq
; CHECK-NEXT: store i32 %.rail, ptr %cq.rail.addr, align 4
; CHECK: %m = call i1 @cqrt_measure_i1(i32 %.rail2)

; ModuleID = 'ghz.c'
source_filename = "ghz.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FF921FB54442D18) #5
  %3 = zext i1 %2 to i8
  store i8 %3, ptr %1, align 1, !tbaa !6
  br label %4

4:                                                ; preds = %0, %4
  %5 = phi i8 [ %3, %0 ], [ %11, %4 ]
  %6 = phi i64 [ 0, %0 ], [ %7, %4 ]
  %7 = add nuw nsw i64 %6, 1
  %8 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %7
  %9 = load i8, ptr %8, align 1, !tbaa !6, !range !10, !noundef !11
  %10 = icmp ne i8 %9, %5
  %11 = zext i1 %10 to i8
  store i8 %11, ptr %8, align 1, !tbaa !6
  %12 = icmp eq i64 %6, 0
  br i1 %12, label %4, label %14, !llvm.loop !12

13:                                               ; preds = %14
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %23

14:                                               ; preds = %4, %14
  %15 = phi i64 [ %24, %14 ], [ 0, %4 ]
  %16 = phi i32 [ %23, %14 ], [ 0, %4 ]
  %17 = shl nsw i32 %16, 1
  %18 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %15
  %19 = load i8, ptr %18, align 1, !tbaa !6, !range !10, !noundef !11
  %20 = trunc nuw i8 %19 to i1
  %21 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %20) #4
  %22 = zext i1 %21 to i32
  %23 = or disjoint i32 %17, %22
  %24 = add nuw nsw i64 %15, 1
  %25 = icmp eq i64 %24, 3
  br i1 %25, label %13, label %14, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
