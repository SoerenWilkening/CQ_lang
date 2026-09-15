; railbank_accept_zeroinit_memset.ll — THE ZERO-INITIALISED BANK, AND THE ONLY
; GATE IN THE TREE THAT CAN SEE WHAT HAPPENS TO ITS INITIALIZER.
; bd `xdu2` / L-1a Increment W1, the SECOND HALF (Track B, session 2026-09-15).
;
; `bool b0[3] = {0};` — `clang -O1` spells the initializer as an
; `llvm.memset.p0.i64(ptr %b, i8 0, i64 3, i1 false)` covering the WHOLE object.
; The type rewrite widens that object from 3 bytes to 12, so the fill must be
; DEALT WITH, and there are exactly two ways to deal with it:
;
;   DELETE it (what ships).  Licensed by C6 TOTALITY: every cell is stored before
;     any cell is loaded, so the fill is never observed.
;   RESCALE it to 12 bytes.  Also sound under C6 — and it writes handle `0` into
;     every cell, and **handle 0 IS A LIVE RAIL in this runtime**
;     (`cqrt_alloc_i1(0) -> h0`).  Under C6 nothing reads it; the day C6 is
;     widened to admit a never-written cell, the rescale hands a MEASURE A LIVE
;     RAIL'S HANDLE while the deletion hands it an uninitialised one.  The
;     deletion has the better failure mode, COUNTERFACTUALLY — the difference is
;     invisible while C6 holds.
;
; ⚠ AND THAT INVISIBILITY WAS MEASURED, NOT ASSUMED.  Injection mutant **M8b**
; (rescale instead of delete) was MISSED by every other railbank fixture, by
; every railbank e2e slice and by stage 2b: the emitted TRACE is byte-identical
; either way, because no cell is ever read before it is written, and
; `free_pairing_check.py` does not model memory at all.  This file's
; `NOTS-NOT: call void @llvm.memset` on the LOWERED module is the only
; instrument in the tree that distinguishes them.  ⚠ The `declare` of
; `llvm.memset` SURVIVES in the lowered module (nothing prunes an unused
; declaration), so the negative must name the CALL and not the symbol — a bare
; `-NOT: memset` would match the declaration and be vacuously red.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `…/trackB/probes/b13_bank_bool_measureloop_zeroinit.c` (the D1/R2 twin of the
; canonical accept, with `bool b0[3] = {0};`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR     --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CALLOC --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS   --input-file=%t.ll %s

; IR: alloca [3 x i32], align 4, !cq.railbank
; IR: %h = call i32 @cqrt_alloc_i1(i1 false)
; IR: store i32 %h, ptr %cq.bank.addr, align 4
; IR: call i1 @cqrt_measure_i1(i32 %{{.*}})

; CALLOC-COUNT-1: call i32 @cqrt_alloc_i1(

; PURE NEGATIVES.  The initializer's CALL is gone; the storage casts are gone;
; the parked rail is left allocated.
; NOTS-NOT: call void @llvm.memset
; NOTS-NOT: cq_template_zext
; NOTS-NOT: cq_template_trunc
; NOTS-NOT: cqrt_free

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
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
