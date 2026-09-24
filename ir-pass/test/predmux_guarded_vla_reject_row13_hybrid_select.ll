; predmux_guarded_vla_reject_row13_hybrid_select.ll —
; DECLINE, and the OWNER MOVED TWICE. [HISTORY, bd xdu2.8:] The bead's own program
; (railbank_dynamic_matrix.c row 13): `for (i<n) if (q && m == n) { a += p[i];
; z -= p[i]; }` with `int` accumulators. E4 now ADMITS the read (no `gate=E4`
; leave line; proof (T), `trips == extent`), PredMux flattens the arm, and the
; 4.4 DATA select over the hybrid condition `and (m == n), (q != 0)` declines at
; SelectClassify's untainted-leaf gate — "a hybrid classical∧quantum conjunction
; is out of scope", which is load-bearing for bd q2wk's E6 rule (B) and is NOT
; this bead's to lift. Same diagnostic string as before, different owner.
;
; ⚠ bd xdu2.13 — xdu2.8's RETIREMENT TRIGGER ("when the hybrid 4.4 select
; lands, this module should ACCEPT") FIRED, AND THE MODULE DID *NOT* ACCEPT; IT
; MOVED TO A THIRD WALL. The hybrid 4.4 select landed: the classical
; leaf `%16` is now the LITERAL of `cq_template_and_i1_hl` and SelectClassify no
; longer declines (the `CHECK-NOT: CQ_CTRL_DBG: decline` below is that witness —
; no control-layer decline fires at all). The module now declines at the LOOP
; layer's round-2 grant re-ask: `-O1` LICM-hoisted `%17 = and i1 %16, %15` into
; the preheader, `lowerLoops` recorded it at ROUND 1 as an invariant register
; root of the loop's iteration-local grant, the select emitter then ERASED that
; tree node (it has no user once the network is minted in the body), and
; `declineRound2FalsifiedRailGrants` treats a NULLED root as a refusal.
; PRE-EXISTING and not literal-specific: a pure-quantum `(q > 1) & (r < 5)` 4.4
; select in the same rolled loop declines with the same string on the
; pre-xdu2.13 binary (TRACK_E_xdu2_13.md §4). That function's own comment
; instructs "an over-decline to FILE, not a fence to relax in place".
; RETIREMENT TRIGGER (re-armed): when the loop layer stops counting a
; condition-tree node the 4.4 emitter consumes as a round-1 root (or re-derives
; roots before refusing a nulled one), this module should ACCEPT; re-derive the
; stream then — the guarded select AND `cq_template_and_i1_hl(…, i1 %16)` must
; both be in it. Do not delete it (L8). Source:
; tests/e2e/railbank_guarded_vla_matrix.c CASE 6.
;
; RUN: env CQ_PREDMUX_DBG=1 CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: gate=E4
; CHECK-NOT: CQ_CTRL_DBG: decline
; CHECK: cq loop lowering: round-1 iteration-local marking falsified by round-2 taint

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
