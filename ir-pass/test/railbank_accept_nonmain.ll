; railbank_accept_nonmain.ll — W1's SECOND HALF OUTSIDE `main`: THE D1 SPINE
; DOOR, AND THE POPULATION THAT ACTUALLY NEEDS IT.
;
; bd `xdu2` / L-1a Increment W1 (Track B, session 2026-09-15).
;
; ⚠ THIS IS NOT A VARIANT — IT IS THE ONLY PLACE THE QUESTION IS ASKABLE.
; `FreePoint::computeFreePoint` short-circuits EVERY handle in `main` to
; `Escaped`, so inside `main` the disposition of a rail parked in a bank cell is
; decided by accident.  Outside `main` it is decided by `isTerminalHandle`, and
; the three outcomes were MEASURED before the fix:
;   * the store is a non-`CallInst` user, so the scan SILENTLY SKIPS it and the
;     rail is nominated as a DEAD terminal;
;   * the store then falls to `FirstUnrecognized` and the module LOUD-DECLINES
;     `cq uncompute: tainted handle reaches an unrecognized user` — an
;     over-decline of the canonical slice written in the house style;
;   * and with the store deleted the spine ADJOINTS AND FREES the rail:
;     `ry(+0.5); ry(-0.5); cqrt_free` per cell, `opt` exit 0, stage 2b
;     `1 verified, 0 violation(s), 0 unproven` — the spine un-preparing and
;     freeing the three qubits the user is about to measure
;     (`trackB/probes/b14_bank_nonmain.c` under `probes/emulate_piece3.sh`).
;
; ⚠ AND THE `main` SHORT-CIRCUIT COVERS ALMOST NOTHING.  MEASURED over an
; 80-slice sample of `tests/e2e/slice_*.c`, compiled `-O1` and attributed per
; defining function: 4 confine the quantum work to `main`, 10 to a non-`main`
; helper, 66 to BOTH — **76 of 80 carry it outside `main`**.  `noinline` is
; load-bearing in the probe: without it `-O1` inlines the helper into `main` and
; the question disappears, which is exactly how a hazard comes to look absent.
;
; The negative on `cqrt_free` below is the other half of the fix: the rail is LEFT
; ALLOCATED (Rule 6's accepted leak), never adjointed and never freed.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `…/trackB/probes/b14_bank_nonmain.c`:
;   #include "CQ.h"
;   __attribute__((noinline)) int kern(void) {
;       bool b0[3]; int s = 0;
;       for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
;       for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
;       return s;
;   }
;   int main(void) { return kern(); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR     --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CALLOC --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS   --input-file=%t.ll %s

; The bank lives in `@kern`, not in `@main`.
; IR: define{{.*}} i32 @kern()
; IR: alloca [3 x i32], align 4, !cq.railbank
; IR: %h = call i32 @cqrt_alloc_i1(i1 false)
; IR: store i32 %h, ptr %cq.bank.addr, align 4
; IR: call i1 @cqrt_measure_i1(i32 %{{.*}})

; CALLOC-COUNT-1: call i32 @cqrt_alloc_i1(

; PURE NEGATIVES — the whole point of the file.  No adjoint rotation, no free,
; and no unrecognized-user decline (the RUN line has no `not`, which is what
; pins the last one).
; NOTS-NOT: cqrt_free
; NOTS-NOT: cq_template_zext
; NOTS-NOT: cq_template_trunc

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @kern() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %9, %2 ]
  %4 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 5.000000e-01) #4
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %4, align 1, !tbaa !6
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 3
  br i1 %10, label %12, label %2, !llvm.loop !12

11:                                               ; preds = %12
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %20

12:                                               ; preds = %2, %12
  %13 = phi i64 [ %21, %12 ], [ 0, %2 ]
  %14 = phi i32 [ %20, %12 ], [ 0, %2 ]
  %15 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %13
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %17) #4
  %19 = zext i1 %18 to i32
  %20 = add nuw nsw i32 %14, %19
  %21 = add nuw nsw i64 %13, 1
  %22 = icmp eq i64 %21, 3
  br i1 %22, label %11, label %12, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #3 {
  %1 = tail call i32 @kern()
  ret i32 %1
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

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
