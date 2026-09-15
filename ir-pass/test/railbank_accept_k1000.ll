; railbank_accept_k1000.ll — K-INDEPENDENCE: the rail bank at N=1000.
; bd `xdu2` / L-1a Increment W1, the SECOND HALF (Track B, session 2026-09-15).
;
; The SAME program as `railbank_accept_bool_prep_measureloop.ll` with the array
; and both trip counts at 1000 instead of 3.
;
; ⚠ WHAT IT PINS, MEASURED: the LOWERED IR IS THE SAME SIZE AT BOTH N.
; `83 non-blank lines at N=3 and 83 at N=1000`, with ONE `cqrt_alloc_i1` site per
; defining function in both, measured WITHOUT `-g` (debug intrinsics would make
; the count a statement about metadata rather than about code).  The capability
; is ROLLED: the bank's cells are a memory object, not N unrolled rails, so
; neither the carve, the promoter, the type rewrite nor the D5 walk has a cost
; or an IR footprint that grows with N.
;
; ⚠ AND IT IS THE FIXTURE THAT WOULD CATCH A SCALARISING REGRESSION SILENTLY.
; `unrollConstTripLoops` refuses both loops by its clause U2 (no `cq_*` call in
; the loop) and `-O1` stamps `llvm.loop.unroll.disable`, so nothing unrolls
; today — but a widening of either would turn this module into a 1000-fold
; cascade that still PASSES a byte-diff, because a rolled and an unrolled program
; emit the same TRACE.  The line count is the only instrument that sees it.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of the
; N=1000 spelling of `tests/e2e/slice_railbank_bool_prep_measureloop.c`'s body.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR     --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CALLOC --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS   --input-file=%t.ll %s

; ⚠ `align 16`, not `align 4`: `clang` already aligned the `[1000 x i8]` object
; to 16, and the rewrite only ever RAISES the alignment to the handle type's ABI
; alignment — never lowers it.  An over-aligned bank is correct; an
; under-aligned one would be a 4-byte store into a 1-byte-aligned object.
; IR: alloca [1000 x i32], align 16, !cq.railbank
; IR: %h = call i32 @cqrt_alloc_i1(i1 false)
; IR: store i32 %h, ptr %cq.bank.addr, align 4
; IR: call i1 @cqrt_measure_i1(i32 %{{.*}})

; ⚠ ITS OWN WHOLE-FILE PREFIX (Rule 12 hygiene defect (a)).  TWO sites, not
; 2000: one per defining function (`@slice` and its inlined copy in `@main`),
; exactly as at N=3.
; CALLOC-COUNT-2: call i32 @cqrt_alloc_i1(

; PURE NEGATIVES.
; NOTS-NOT: cq_template_zext
; NOTS-NOT: cq_template_trunc
; NOTS-NOT: cqrt_free
; NOTS-NOT: 1000 x i8

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = alloca [1000 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 1000, ptr nonnull %1) #3
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %9, %2 ]
  %4 = getelementptr inbounds [1000 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 5.000000e-01) #3
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %4, align 1, !tbaa !6
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 1000
  br i1 %10, label %12, label %2, !llvm.loop !12

11:                                               ; preds = %12
  call void @llvm.lifetime.end.p0(i64 1000, ptr nonnull %1) #3
  ret i32 %20

12:                                               ; preds = %2, %12
  %13 = phi i64 [ %21, %12 ], [ 0, %2 ]
  %14 = phi i32 [ %20, %12 ], [ 0, %2 ]
  %15 = getelementptr inbounds [1000 x i8], ptr %1, i64 0, i64 %13
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %17) #3
  %19 = zext i1 %18 to i32
  %20 = add nuw nsw i32 %14, %19
  %21 = add nuw nsw i64 %13, 1
  %22 = icmp eq i64 %21, 1000
  br i1 %22, label %11, label %12, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [1000 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 1000, ptr nonnull %1) #3
  br label %2

2:                                                ; preds = %2, %0
  %3 = phi i64 [ 0, %0 ], [ %9, %2 ]
  %4 = getelementptr inbounds [1000 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 5.000000e-01) #3
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %4, align 1, !tbaa !6
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 1000
  br i1 %10, label %11, label %2, !llvm.loop !12

11:                                               ; preds = %2, %11
  %12 = phi i64 [ %17, %11 ], [ 0, %2 ]
  %13 = getelementptr inbounds [1000 x i8], ptr %1, i64 0, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %15) #3
  %17 = add nuw nsw i64 %12, 1
  %18 = icmp eq i64 %17, 1000
  br i1 %18, label %19, label %11, !llvm.loop !15

19:                                               ; preds = %11
  call void @llvm.lifetime.end.p0(i64 1000, ptr nonnull %1) #3
  ret i32 0
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
