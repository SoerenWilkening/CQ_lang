; loop_leak_dephase_accept_marked_rootmint.ll — ACCEPT (bd `test_C_libtooling-s82e`,
; owner ruling D4 of 2026-09-14c). THE POSITIVE CONTROL, and the fixture most
; likely to break if the D4 decline is ever widened.
;
;     int y = 5; cq_theta(&y, .5);
;     for (k = 1; k <= 2; ++k) if ((y >> k) & 1) cq_phi(.3);
;     cq_theta(&y, .9);                  // THE SAME POST-LOOP INTERFERENCE
;     return cq_measure(y);
;
; It carries the IDENTICAL hazard shape to `loop_leak_dephase_reject_noregion_live
; .ll` — an in-loop derived chain off a loop-invariant register that is re-rotated
; after the loop — and it is CORRECT, because `invariantRegisterRoots` (3qlq Inc 1
; part A) admits the classical-arg-0 root mint, `markIfRailLocal` marks the body,
; and the whole-DAG spine discharges IN-BODY once per trip. MEASURED: rolled and
; hand-unrolled are BYTE-IDENTICAL at 22 trace lines, and the lowered IR puts the
; `_unc` and BOTH `cqrt_free` inside the loop body block while the `cqrt_ry_i32(h0,
; 9.000000e-01)` sits in the exit block.
;
; ⚠ WHY IT IS THE CONTROL AND NOT JUST ANOTHER ACCEPT. Without it the two D4
; decline fixtures read as "rolled loops that re-rotate a register are refused",
; which is false and would licence exactly the over-decline the owner rejected.
; With it they read as what they are: "an UNMARKED body's leak is refused; a MARKED
; body's discharge is not." Conjunct (1) of `declineDephasingUnmarkedLoopRails` is
; the whole difference, and this file is the only thing pinning it.
;
; ⚠⚠ THE SECOND HALF OF THAT SENTENCE IS EXACT AND THE FIRST HALF OVER-CLAIMS.
; "An UNMARKED body's leak is refused" is NOT what the fence does: it refuses the
; sub-case its conjuncts describe, and those conjuncts have been measured wrong
; once already. Rule-13 round 1 track β (2026-09-14c) found two surviving members
; — an interfering rotation INSIDE the body (bd `test_C_libtooling-c767`, P1) and
; a tainted COMPARE used as data (bd `test_C_libtooling-7845`, P1) — both
; PRE-EXISTING over-accepts, both CLOSED by the 2026-09-15 widening, and neither
; ever touching this file's own verdict.
;
; WHAT THIS FILE STILL PINS, UNCHANGED AND MEASURED: conjunct (1). Its program is
; not a leak at all — rolled and hand-unrolled are BYTE-IDENTICAL at 22 trace
; lines — so it is the control for "a MARKED body's discharge is not refused",
; which is the half a widening of conjuncts (2) or (3) is most likely to break.
; ⚠ L8 RETIREMENT TRIGGER FIRED AND WAS RE-DERIVED BY MEASUREMENT, not assumed
; (`CLAUDE.md` L7-with-a-twist). The trigger named bd `c767` / bd `7845`; BOTH
; landed on 2026-09-15 — conjunct (2) lost its `L->contains` skip and conjunct (3)
; became the membership question `mintsOutOfPlaceTemplateRail` — and this file was
; re-run FIRST, as the trigger instructed: `s3_live_rootmint_region`
; `ORACLE A:22 lines | SUBJECT A:22 lines`, and the fixture PASSES on the widened
; binary `f667cf90436bd31d…`. It did not decline, so the widening stayed narrow
; and did NOT become the blanket decline owner ruling D2 explicitly REJECTED.
; ⚠ NEXT RETIREMENT TRIGGER: any further widening of conjuncts (2) or (3), and bd
; `tu9q`. Re-run this file first, every time.
; The full coverage claim is at `declineDephasingUnmarkedLoopRails` in
; `ir-pass/src/LoopLowering.cpp`; do not restate it from here.
;
; ⚠ THE CHECKS BELOW WERE REWRITTEN AFTER AN INJECTION MATRIX SCORED 5 OF 5
; APPLIED MUTATIONS **MISSED** AGAINST THE FIRST DRAFT — including deleting the
; `_unc` and deleting a `cqrt_free`, i.e. the very discharge this file exists to
; pin. The first draft's `INBODY` block named the LAST two lines of the stream and
; nothing before them, so a mutation one line earlier walked straight through it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RY < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @slice
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
;
; the post-loop interference sits in the EXIT block, which `-O1` prints BEFORE the
; body — so this also pins that the discharge below has not been sunk past it:
; (a `#dbg_value` record intervenes here, so this pair is two plain positive
; directives rather than an adjacency one.)
; CHECK: call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)
; CHECK: %m = call i32 @cqrt_measure_i32(i32 %h)
;
; THE WHOLE IN-BODY STREAM, CONTIGUOUS AND IN ORDER: mint, flag, the bracketed
; kickback, the flag strip, THE RAIL'S OWN ADJOINT, and BOTH proven-|0> frees.
; Every one of the five mutations the matrix applies deletes, moves or inserts a
; line inside this run, and `CHECK-NEXT` is what makes each of them fail.
; CHECK: %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 %{{[0-9]+}})
; CHECK-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %h_cmp)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %h_cmp)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
;
; ⚠ THE TRAILING LABEL IS LOAD-BEARING (see the twin fixture's note): `-O1`
; inlines `@slice` into `@main`, so without it the positives above can all be
; satisfied by the `@main` copy and a deletion from `@slice` scores MISSED.
; CHECK-LABEL: define i32 @main
;
; COUNT-COUNT-4: call void @cqrt_free(
; COUNT-NOT: call void @cqrt_free(
;
; and exactly two rotations per function, so a stray uncontrolled `cqrt_ry` on
; the user register cannot hide (its own prefix — a count inside an ordered block
; windows every negative after it, Rule 12 fixture-hygiene defect (a)):
; RY-COUNT-4: call void @cqrt_ry_i32(
; RY-NOT: call void @cqrt_ry_i32(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !18
    #dbg_value(i32 %1, !15, !DIExpression(), !19)
    #dbg_value(i32 1, !16, !DIExpression(), !20)
  br label %5, !dbg !21

2:                                                ; preds = %11
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !22
    #dbg_value(i32 %3, !15, !DIExpression(), !19)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !23
  ret i32 %4, !dbg !24

5:                                                ; preds = %0, %11
  %6 = phi i32 [ 1, %0 ], [ %12, %11 ]
    #dbg_value(i32 %6, !16, !DIExpression(), !20)
  %7 = shl nuw nsw i32 1, %6, !dbg !25
  %8 = and i32 %7, %1, !dbg !25
  %9 = icmp eq i32 %8, 0, !dbg !25
  br i1 %9, label %11, label %10, !dbg !28

10:                                               ; preds = %5
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !29
  br label %11, !dbg !29

11:                                               ; preds = %5, %10
  %12 = add nuw nsw i32 %6, 1, !dbg !30
    #dbg_value(i32 %12, !16, !DIExpression(), !20)
  %13 = icmp eq i32 %12, 3, !dbg !31
  br i1 %13, label %2, label %5, !dbg !21, !llvm.loop !32
}

declare !dbg !36 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !41 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !44 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !47 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !48
    #dbg_value(i32 %1, !15, !DIExpression(), !50)
    #dbg_value(i32 1, !16, !DIExpression(), !51)
  br label %2, !dbg !52

2:                                                ; preds = %8, %0
  %3 = phi i32 [ 1, %0 ], [ %9, %8 ]
    #dbg_value(i32 %3, !16, !DIExpression(), !51)
  %4 = shl nuw nsw i32 1, %3, !dbg !53
  %5 = and i32 %4, %1, !dbg !53
  %6 = icmp eq i32 %5, 0, !dbg !53
  br i1 %6, label %8, label %7, !dbg !54

7:                                                ; preds = %2
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !55
  br label %8, !dbg !55

8:                                                ; preds = %7, %2
  %9 = add nuw nsw i32 %3, 1, !dbg !56
    #dbg_value(i32 %9, !16, !DIExpression(), !51)
  %10 = icmp eq i32 %9, 3, !dbg !57
  br i1 %10, label %11, label %2, !dbg !52, !llvm.loop !58

11:                                               ; preds = %8
  %12 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !60
    #dbg_value(i32 %12, !15, !DIExpression(), !50)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !61
  ret i32 %13, !dbg !62
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!9}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/s3_live_rootmint_region.c", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "c97d6c736b8ef5f9435837ab194802e5")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "k", scope: !17, file: !8, line: 8, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!18 = !DILocation(line: 7, column: 13, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 0, scope: !17)
!21 = !DILocation(line: 8, column: 5, scope: !17)
!22 = !DILocation(line: 10, column: 9, scope: !10)
!23 = !DILocation(line: 11, column: 12, scope: !10)
!24 = !DILocation(line: 11, column: 5, scope: !10)
!25 = !DILocation(line: 9, column: 22, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !8, line: 9, column: 13)
!27 = distinct !DILexicalBlock(scope: !17, file: !8, line: 8, column: 5)
!28 = !DILocation(line: 9, column: 13, scope: !27)
!29 = !DILocation(line: 9, column: 27, scope: !26)
!30 = !DILocation(line: 8, column: 29, scope: !27)
!31 = !DILocation(line: 8, column: 23, scope: !27)
!32 = distinct !{!32, !21, !33, !34, !35}
!33 = !DILocation(line: 9, column: 37, scope: !17)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.unroll.disable"}
!36 = !DISubprogram(name: "cq_theta_si32", scope: !37, file: !37, line: 38, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!38 = !DISubroutineType(types: !39)
!39 = !{!13, !13, !40}
!40 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!41 = !DISubprogram(name: "cq_phi", scope: !37, file: !37, line: 73, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DISubroutineType(types: !43)
!43 = !{null, !40}
!44 = !DISubprogram(name: "cq_measure_si32", scope: !37, file: !37, line: 83, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DISubroutineType(types: !46)
!46 = !{!13, !13}
!47 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!48 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !49)
!49 = distinct !DILocation(line: 13, column: 25, scope: !47)
!50 = !DILocation(line: 0, scope: !10, inlinedAt: !49)
!51 = !DILocation(line: 0, scope: !17, inlinedAt: !49)
!52 = !DILocation(line: 8, column: 5, scope: !17, inlinedAt: !49)
!53 = !DILocation(line: 9, column: 22, scope: !26, inlinedAt: !49)
!54 = !DILocation(line: 9, column: 13, scope: !27, inlinedAt: !49)
!55 = !DILocation(line: 9, column: 27, scope: !26, inlinedAt: !49)
!56 = !DILocation(line: 8, column: 29, scope: !27, inlinedAt: !49)
!57 = !DILocation(line: 8, column: 23, scope: !27, inlinedAt: !49)
!58 = distinct !{!58, !52, !59, !34, !35}
!59 = !DILocation(line: 9, column: 37, scope: !17, inlinedAt: !49)
!60 = !DILocation(line: 10, column: 9, scope: !10, inlinedAt: !49)
!61 = !DILocation(line: 11, column: 12, scope: !10, inlinedAt: !49)
!62 = !DILocation(line: 13, column: 18, scope: !47)
