; railbank_stale_accept_parked_parent_add_stays_out_of_place.ll — bd `xdu2.1`
; (Track B, session 2026-09-24-railbank-parallel).
;
; THE dtzb / M-C HALF OF THE MEMORY HOP.  The stale-reader fence walks for
; `cq_theta_` gates and NOT for an in-place `add`/`xor` (the `WireWalk.h`
; vocabulary gap, bd `a3z7`), so the ONLY thing that keeps a parked rail from
; being relabelled by M-C's late in-place conversion (`ArithLowering.cpp`,
; `inPlaceFenceHolds`) and then read stale through the bank is that
; conversion's own refusal.  Here `q` is parked in every cell, `t = q + 3` is
; the M-C candidate on `q`, and the cells are measured AFTER the add — so the
; conversion MUST stay out of place (`cq_template_add_i32_hl` minting a fresh
; rail), or the three bank measures would observe `q + 3` where the source says
; `q`.  The emitted stream is BYTE-IDENTICAL to the array-free register twin
; (`tools/railbank_twin_pairs/p10_parked_parent_add.reg.c`, measured).
;
; ⚠ WHAT REFUSES IT, MEASURED, AND IT IS NOT WHAT THE SOURCE COMMENT SAID.
; `ArithLowering.cpp`'s retirement trigger claimed the case "cannot" arise
; because "D5 admits only a measurement … so there is no reader after the
; conversion to be staled".  This module IS that reader (a bank `cq_measure`
; after the site).  The refusal is G7 clause (e): the parking `store` is a
; plain-IR prior use of `q`, and `priorUseIsSettled` returns false for any
; non-call user.  Mutating that clause to admit a `StoreInst` turns this module
; into `cqrt_addc_i32(%h, 3)` and this fixture red (TRACK_B.md §4).
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
;   __attribute__((noinline)) int slice(int seed) {
;     int q = seed; cq_theta(&q, 0.5);
;     int b[3]; int s = 0;
;     for (int i = 0; i < 3; ++i) b[i] = q;
;     int t = q + 3;
;     s += cq_measure(t);
;     for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
;     return s;
;   }
;   int main(void) { return slice(1); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR    --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CMEAS --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS  --input-file=%t.ll %s
;
; IR: alloca [3 x i32], align 4, !cq.railbank
; IR: %h = call i32 @cqrt_alloc_i32(
; IR: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; IR: %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 3)
; IR: call i32 @cqrt_measure_i32(i32 %h_op)
; IR: store i32 %h, ptr
; IR: [[CELL:%[0-9]+]] = load i32, ptr
; IR: call i32 @cqrt_measure_i32(i32 [[CELL]])
;
; ⚠ One whole-file prefix per count (Rule 12 (a)): one out-of-place measure and
; one rolled bank measure.
; CMEAS-COUNT-2: call i32 @cqrt_measure_i32(
;
; PURE NEGATIVES: no in-place conversion of the parked parent, no qram, no free
; of a measured or parked rail.
; NOTS-NOT: cqrt_addc_
; NOTS-NOT: cqrt_qram_
; NOTS-NOT: cqrt_free

source_filename = "s13_fixed_dtzb_add_measure_first.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [3 x i32], align 4
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %2) #4
  br label %7

4:                                                ; preds = %7
  %5 = add nsw i32 %3, 3
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  br label %13

7:                                                ; preds = %1, %7
  %8 = phi i64 [ 0, %1 ], [ %10, %7 ]
  %9 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %8
  store i32 %3, ptr %9, align 4, !tbaa !6
  %10 = add nuw nsw i64 %8, 1
  %11 = icmp eq i64 %10, 3
  br i1 %11, label %4, label %7, !llvm.loop !10

12:                                               ; preds = %13
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %2) #4
  ret i32 %19

13:                                               ; preds = %4, %13
  %14 = phi i64 [ 0, %4 ], [ %20, %13 ]
  %15 = phi i32 [ %6, %4 ], [ %19, %13 ]
  %16 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %14
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #4
  %19 = add nsw i32 %18, %15
  %20 = add nuw nsw i64 %14, 1
  %21 = icmp eq i64 %20, 3
  br i1 %21, label %12, label %13, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #3 {
  %1 = tail call i32 @slice(i32 noundef 1)
  ret i32 %1
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
