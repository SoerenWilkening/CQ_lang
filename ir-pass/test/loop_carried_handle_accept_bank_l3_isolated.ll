; loop_carried_handle_accept_bank_l3_isolated.ll — bd `test_C_libtooling-zujr`,
; THE ISOLATING POSITIVE FOR THE ONE WIDENING IN THAT INCREMENT THAT IS **NOT**
; GATED ON `loopCarriedHandlePhi` (Rule-13 round 1, F-2).
;
; `railLocalQualifies`' (L3) clause now exempts a store that PARKS A RAIL IN A
; PROVEN `!cq.railbank` ALLOCA with an UNTAINTED pointer operand.  THIS MODULE
; HAS NO LOOP-CARRIED HANDLE φ ANYWHERE — `q` is loop-INVARIANT and the only
; header φ is the classical induction variable — so every conjunct of
; `loopCarriedHandlePhi` is vacuous here and the accept is (L3)'s alone.  Without
; that file, the increment's only witness for this half was an e2e pair, and a
; widening with no lit fixture of its own has regression cover but no red-green.
;
; ⚠ THE DERIVED CONDITION `(q >> i) & 1` IS WHAT MAKES IT A WITNESS, not
; decoration.  It is the only condition kind in this family that mints
; `cq_template_*` rails in the body PER TRIP, i.e. the only one whose per-trip
; chain is the SPINE's to discharge rather than an emitter's — the 19-vs-27 shape
; `iterationLocalRollable`'s clause (c3) is built on.  A bank with a plain compare
; condition would accept here and prove nothing.
;
; MEASURED: on the ORACLE (`cq-opt` 07d93784…) this module DECLINED
; `cq controlled lowering: control flow inside a loop body under quantum control`;
; its hand-unrolled twin compiled on both binaries, and the two TRACES are
; BYTE-IDENTICAL, 36 lines each (`tests/e2e/slice_loop_bank_derived_cond{,_twin}`).
; So the exemption does not merely fail to break anything: it CLOSES A LEAK the
; decline was hiding.
;
; ⚠ THE TAINTED-INDEX HALF IS A DIFFERENT PROGRAM AND IS UNTOUCHED —
; `$SES/probes/a1_taintedidx.c` still declines `cq QRAM access: tainted-index
; memory access inside a loop` on both binaries.  The exemption's pointer-operand
; conjunct is what keeps them apart.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=CHECK --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOPROMO --input-file=%t.ll %s
;
; EVERY PER-TRIP RAIL IS DISCHARGED: the `and` chain and the compare flag are both
; `_unc`'d and freed inside the activation.  That is the marking working, and it is
; the whole point of the exemption.
; ⚠ `-O1` REWRITES `(q >> i) & 1` AS `q & (1 << i)` — the mask is the loop-variant
; operand and the register is arg 0.  Read the stream, not the source (Rule 9).
; CHECK: %h_op = call i32 @cq_template_and_i32_hl(i32 %[[Q:[0-9a-zA-Z._]+]], i32 %[[M:[0-9a-zA-Z._]+]])
; CHECK: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; CHECK: %h{{[0-9]*}} = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h{{[0-9]*}}, double 5.000000e-01)
; CHECK: call void @cqrt_x(i32 %h_cmp)
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 0)
; CHECK: call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %[[Q]], i32 %[[M]])
; CHECK: call void @cqrt_free(i32 %h_op)
; CHECK: call void @cqrt_free(i32 %h_cmp)
;
; AND NO PROMOTION HAPPENED — there is no carried handle to promote.  Its own
; whole-file prefix, because a positive above a negative WINDOWS it.
; NOPROMO-NOT: cq.carried

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #3
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #3
  br label %22

3:                                                ; preds = %34
  %4 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %5 = trunc nuw i8 %4 to i1
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #3
  %7 = zext i1 %6 to i32
  %8 = getelementptr inbounds i8, ptr %1, i64 1
  %9 = load i8, ptr %8, align 1, !tbaa !6, !range !10, !noundef !11
  %10 = trunc nuw i8 %9 to i1
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10) #3
  %12 = zext i1 %11 to i32
  %13 = add nuw nsw i32 %12, %7
  %14 = getelementptr inbounds i8, ptr %1, i64 2
  %15 = load i8, ptr %14, align 1, !tbaa !6, !range !10, !noundef !11
  %16 = trunc nuw i8 %15 to i1
  %17 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %16) #3
  %18 = zext i1 %17 to i32
  %19 = add nuw nsw i32 %13, %18
  %20 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %21 = add nsw i32 %19, %20
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #3
  ret i32 %21

22:                                               ; preds = %0, %34
  %23 = phi i64 [ 0, %0 ], [ %35, %34 ]
  %24 = trunc nuw nsw i64 %23 to i32
  %25 = shl nuw nsw i32 1, %24
  %26 = and i32 %25, %2
  %27 = icmp eq i32 %26, 0
  br i1 %27, label %34, label %28

28:                                               ; preds = %22
  %29 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %23
  %30 = load i8, ptr %29, align 1, !tbaa !6, !range !10, !noundef !11
  %31 = trunc nuw i8 %30 to i1
  %32 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %31, double noundef 5.000000e-01) #3
  %33 = zext i1 %32 to i8
  store i8 %33, ptr %29, align 1, !tbaa !6
  br label %34

34:                                               ; preds = %22, %28
  %35 = add nuw nsw i64 %23, 1
  %36 = icmp eq i64 %35, 3
  br i1 %36, label %3, label %22, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
