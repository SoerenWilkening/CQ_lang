; predmux_guarded_vla_reject_row13_hybrid_select.ll —
; ⚠ AN ACCEPT UNDER ITS OLD `_reject_` NAME, AND THE NAME IS KEPT ON PURPOSE (L8;
; bd `gahu`'s rule: a `git mv` can be resurrected by a merge). bd xdu2.16 retired
; the THIRD wall below, so the retirement trigger this header carried FIRED — and
; this time the module DOES accept. Re-derived on the xdu2.16 binary, not predicted.
;
; [HISTORY, bd xdu2.8:] The bead's own program (railbank_dynamic_matrix.c row 13):
; `for (i<n) if (q && m == n) { a += p[i]; z -= p[i]; }` with `int` accumulators.
; E4 ADMITS the read (no `gate=E4` leave line; proof (T), `trips == extent`),
; PredMux flattens the arm, and the 4.4 DATA select over the hybrid condition
; `and (m == n), (q != 0)` then declined at SelectClassify's untainted-leaf gate.
; [HISTORY, bd xdu2.13:] the hybrid 4.4 select landed (the classical leaf `%16` is
; the LITERAL of `cq_template_and_i1_hl`) and the module moved to a THIRD wall, the
; loop layer's round-2 grant re-ask: `-O1` LICM-hoisted `%17 = and i1 %16, %15`
; into the preheader, `lowerLoops` recorded it at ROUND 1 as an invariant register
; root, the second select's emitter ERASED that tree node, and
; `declineRound2FalsifiedRailGrants` treated the NULLED root as a refusal.
;
; bd xdu2.16 — THE WALL MOVED AND THE MODULE ACCEPTS. A nulled root is no longer a
; refusal by itself: the grant is re-derived from scratch under FINAL taint by
; `invariantRegisterRoots` and must be TOTAL (it is — the body now reads only `%12`,
; the root mint `q`, through the two emitters' in-body flag mints; the carried `a`
; and `z` handle variables are clause (i)'s). Measured on this file: the pre-change
; ORACLE `438c77bf45c02e3e` exits 1 with the loop string; the xdu2.16 binary exits
; 0, stage 2b STRICT `4 verified, 0 violation(s), 0 unproven`.
;
; THE STREAM TO READ IT BY (the loop body, per trip): the guarded read's
; `load(select(freeze idx <u freeze extent), &p[idx], @cq.guarded.read.zero)`
; (bd xdu2.8), the two chain ops on the CARRIED handles, then TWO independent
; networks — one per select, because the shared `and` is re-minted per consumer:
; `h_cmp = icmp_ne_hl(h, 0)`, `gl = and_i1_hl(h_cmp, i1 zeroext %14)` with the
; classical `m == n` (`%14`, hoisted, untainted, NOT a root) as the literal, the
; X-bracketed copies into a fresh `%out`, `and_i1_hl_unc` with the SAME literal,
; free(gl), the compare strip, free(h_cmp). `h` (the user's `q`) is only ever a
; template operand and is never freed or bracketed. Source:
; tests/e2e/railbank_guarded_vla_matrix.c CASE 6 (now an accept row there and in
; railbank_dynamic_matrix.c row 13).
;
; RUN: env CQ_PREDMUX_DBG=1 CQ_CTRL_DBG=1 %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s 2> %t.err > %t.ll
; RUN: %filecheck %s --check-prefix=DBG --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.ll
; ⚠ MEASURED: with both debug variables set the accepting run writes 0 BYTES of
; stderr (PredMux and the control layer log only a LEAVE / a DECLINE), so the DBG
; negatives below hold on an empty stream and pin only "no leave, no decline, no
; diagnostic" — the ACCEPT itself is pinned by the RUN line's exit code (no `not`)
; and by the stream checks.
; DBG-NOT: gate=E4
; DBG-NOT: CQ_CTRL_DBG: decline
; DBG-NOT: cq loop lowering
; DBG-NOT: error:
;
; CHECK-LABEL: define internal fastcc i32 @slice(
; CHECK:      %[[H:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      %[[LIT:[0-9]+]] = icmp eq i32 %1, %0
; CHECK:      %cq.gr.addr = select i1 %cq.gr.inb, ptr %cq.gr.cell, ptr @cq.guarded.read.zero
; CHECK-NEXT: %[[LD:[0-9]+]] = load i32, ptr %cq.gr.addr
; CHECK-NEXT: %[[OPA:h_op[0-9]*]] = call i32 @cq_template_add_i32_hl(i32 %[[A:[0-9]+]], i32 %[[LD]])
; CHECK-NEXT: %[[OPZ:h_op[0-9]*]] = call i32 @cq_template_sub_i32_hl(i32 %[[Z:[0-9]+]], i32 %[[LD]])
; CHECK-NEXT: %[[F1:h_cmp[0-9]*]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: %[[G1:gl[0-9]*]] = call i32 @cq_template_and_i1_hl(i32 %[[F1]], i1 zeroext %[[LIT]])
; CHECK-NEXT: %[[O1:out[0-9]*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G1]], i32 %[[OPA]], i32 %[[O1]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G1]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G1]], i32 %[[A]], i32 %[[O1]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G1]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[G1]], i32 %[[F1]], i1 zeroext %[[LIT]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G1]])
; CHECK-NEXT: call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %[[F2:h_cmp[0-9]*]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: %[[G2:gl[0-9]*]] = call i32 @cq_template_and_i1_hl(i32 %[[F2]], i1 zeroext %[[LIT]])
; CHECK-NEXT: %[[O2:out[0-9]*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G2]], i32 %[[OPZ]], i32 %[[O2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G2]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G2]], i32 %[[Z]], i32 %[[O2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G2]])
; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[G2]], i32 %[[F2]], i1 zeroext %[[LIT]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G2]])
; CHECK-NEXT: call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[F2]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
;
; NEG-NOT: and i1
; NEG-NOT: cqrt_alloc_i1(i1 %
; NEG-NOT: cqrt_toffoli
; NEG-NOT: cqrt_free(i32 %h{{[0-9]*}})
; NEG-NOT: cq.predmux
; CNT-COUNT-2: call i32 @cq_template_and_i1_hl(
; CNT-NOT: call i32 @cq_template_and_i1_hl(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 1
  %4 = tail call fastcc i32 @slice(i32 noundef %3, i32 noundef %0)
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = icmp slt i32 %0, 1
  %4 = icmp slt i32 %1, 1
  %5 = or i1 %3, %4
  br i1 %5, label %48, label %6

6:                                                ; preds = %2
  %7 = zext nneg i32 %1 to i64
  %8 = tail call ptr @llvm.stacksave.p0()
  %9 = alloca i32, i64 %7, align 16
  %10 = zext nneg i32 %1 to i64
  br label %19

11:                                               ; preds = %19
  %12 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #4
  %13 = icmp sgt i32 %0, 0
  br i1 %13, label %14, label %26

14:                                               ; preds = %11
  %15 = icmp ne i32 %12, 0
  %16 = icmp eq i32 %1, %0
  %17 = and i1 %16, %15
  %18 = zext nneg i32 %0 to i64
  br label %34

19:                                               ; preds = %6, %19
  %20 = phi i64 [ 0, %6 ], [ %24, %19 ]
  %21 = getelementptr inbounds i32, ptr %9, i64 %20
  %22 = trunc i64 %20 to i32
  %23 = add i32 %22, 3
  store i32 %23, ptr %21, align 4, !tbaa !6
  %24 = add nuw nsw i64 %20, 1
  %25 = icmp eq i64 %24, %10
  br i1 %25, label %11, label %19, !llvm.loop !10

26:                                               ; preds = %43, %11
  %27 = phi i32 [ 0, %11 ], [ %44, %43 ]
  %28 = phi i32 [ 0, %11 ], [ %45, %43 ]
  %29 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  %30 = tail call i32 @cq_measure_si32(i32 noundef %27) #4
  %31 = add nsw i32 %30, %29
  %32 = tail call i32 @cq_measure_si32(i32 noundef %28) #4
  %33 = add nsw i32 %31, %32
  tail call void @llvm.stackrestore.p0(ptr %8)
  br label %48

34:                                               ; preds = %14, %43
  %35 = phi i64 [ 0, %14 ], [ %46, %43 ]
  %36 = phi i32 [ 0, %14 ], [ %45, %43 ]
  %37 = phi i32 [ 0, %14 ], [ %44, %43 ]
  br i1 %17, label %38, label %43

38:                                               ; preds = %34
  %39 = getelementptr inbounds i32, ptr %9, i64 %35
  %40 = load i32, ptr %39, align 4, !tbaa !6
  %41 = add nsw i32 %40, %37
  %42 = sub nsw i32 %36, %40
  br label %43

43:                                               ; preds = %34, %38
  %44 = phi i32 [ %41, %38 ], [ %37, %34 ]
  %45 = phi i32 [ %42, %38 ], [ %36, %34 ]
  %46 = add nuw nsw i64 %35, 1
  %47 = icmp eq i64 %46, %18
  br i1 %47, label %26, label %34, !llvm.loop !13

48:                                               ; preds = %2, %26
  %49 = phi i32 [ %33, %26 ], [ 0, %2 ]
  ret i32 %49
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
