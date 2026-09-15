; loop_leak_dephase_reject_nested_iterlocal_inner.ll — DECLINE. bd
; `test_C_libtooling-emkg`, THE PRE-EXISTING FACE (F-1a). Same defect as its
; sibling `…_nested_marked_inner.ll` — conjunct (1) of
; `declineDephasingUnmarkedLoopRails` read `L->blocks()`, which includes every
; strictly-deeper subloop's blocks, so a marked INNER loop silenced the fence for
; its enclosing OUTER loop — but reached through a DIFFERENT MARKER, and this one
; NEEDS NEITHER 2026-09-15 TRACK: it reproduces on the ORACLE `0e280fc6…`.
;
; ⚠ THIS FILE IS WHY THE SIBLING ALONE IS NOT ENOUGH. The sibling is pinned only
; where bd `test_C_libtooling-tu9q`'s root-mint escape can reach; delete this one
; and a future revert of that escape would take the fix's only witness with it,
; leaving the pre-existing hole unpinned and green.
;
; THE PROGRAM (`loopfix/probes/n1_nested_marked_inner.c`, stage-1 verbatim,
; `clang -O1 -g`):
;
;     int y = cq_theta(5, 0.5);
;     for (i = 1; i <= 2; ++i) {
;         s += cq_measure((y >> i) & 1);        // the OUTER body rail
;         for (j = 0; j < 2; ++j) {
;             int u = cq_theta(6, 0.4);         // FULLY ITERATION-LOCAL inner body
;             s += cq_measure((u >> j) & 1);
;         }
;     }
;     y = cq_theta(y, 0.9);                     // the interference (Rule 8)
;     return s + cq_measure(y);
;
; THE MARKER HERE IS `markIfIterationLocal`, not `markIfRailLocal`: the inner
; loop's whole body is iteration-local (`u` is minted and consumed inside it), so
; the inner loop is marked on EVERY binary this project has shipped — and the
; outer loop, whose own `(y >> i) & 1` rail is a which-path copy of `y`, left the
; fence at conjunct (1) on that marking.
;
; MEASURED: ACCEPT on the ORACLE `0e280fc6…` at 38 trace lines, ACCEPT on the
; merged pre-fix binary `ce3f8f3ddf611acc` at 38, against the hand-unrolled twin's
; 42 on both (`n1_nested_marked_inner_un.c` — the OUTER loop unrolled, the inner
; left rolled). The four missing lines are the outer body's two
; `cq_template_lshr_i32_hl_unc` + `cqrt_free` pairs, standing undischarged at
; `cqrt_ry_i32(h0, 0.9)`. ⚠ NOT A TWIN ARTEFACT: the twin differs from the subject
; by the OUTER loop only, the inner is rolled in both halves, and the delta is
; exactly 2 x (`_unc` + free) on rails the twin's own trace shows discharged.
;
; ⚠ THE SOURCE OF THIS FINDING IS A RETIREMENT TRIGGER THAT FIRED AS WRITTEN.
; `mintsOutOfPlaceTemplateRail`'s block says *"NOTHING MEASURES HOW MANY MEMBERS
; THE CLASS HAS"* and names *"any NEW member of the class"*. This is that member,
; found in one round.
;
; ⚠ Rule 12 hygiene (b): a `DS_Error` decline writes 0 BYTES to stdout, so the
; property is the RUN line's `not` inversion, never an IR-text `CHECK-NOT`.
; Validated by BINARY MUTATION — on the pre-fix binary this file does NOT pass.
;
; ⚠ L8 RETIREMENT TRIGGER: see the sibling's. Do not `git mv` this file.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: n1_nested_marked_inner.c:11:14: in function slice
; CHECK-SAME: cq loop lowering: rolled body leaks a rail entangled with a rotated register

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !26
    #dbg_value(i32 %1, !15, !DIExpression(), !27)
    #dbg_value(i32 0, !16, !DIExpression(), !27)
    #dbg_value(i32 1, !17, !DIExpression(), !28)
  br label %6, !dbg !29

2:                                                ; preds = %13
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !30
    #dbg_value(i32 %3, !15, !DIExpression(), !27)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !31
  %5 = add nsw i32 %4, %23, !dbg !32
  ret i32 %5, !dbg !33

6:                                                ; preds = %0, %13
  %7 = phi i32 [ 1, %0 ], [ %14, %13 ]
  %8 = phi i32 [ 0, %0 ], [ %23, %13 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !28)
    #dbg_value(i32 %8, !16, !DIExpression(), !27)
  %9 = lshr i32 %1, %7, !dbg !34
  %10 = and i32 %9, 1, !dbg !34
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !34
  %12 = add nsw i32 %11, %8, !dbg !35
    #dbg_value(i32 %12, !16, !DIExpression(), !27)
    #dbg_value(i32 0, !19, !DIExpression(), !36)
  br label %16, !dbg !37

13:                                               ; preds = %16
  %14 = add nuw nsw i32 %7, 1, !dbg !38
    #dbg_value(i32 %14, !17, !DIExpression(), !28)
    #dbg_value(i32 %23, !16, !DIExpression(), !27)
  %15 = icmp eq i32 %14, 3, !dbg !39
  br i1 %15, label %2, label %6, !dbg !29, !llvm.loop !40

16:                                               ; preds = %6, %16
  %17 = phi i32 [ 0, %6 ], [ %24, %16 ]
  %18 = phi i32 [ %12, %6 ], [ %23, %16 ]
    #dbg_value(i32 %17, !19, !DIExpression(), !36)
    #dbg_value(i32 %18, !16, !DIExpression(), !27)
  %19 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !44
    #dbg_value(i32 %19, !23, !DIExpression(), !45)
  %20 = lshr i32 %19, %17, !dbg !46
  %21 = and i32 %20, 1, !dbg !46
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #2, !dbg !46
  %23 = add nsw i32 %22, %18, !dbg !47
    #dbg_value(i32 %23, !16, !DIExpression(), !27)
  %24 = add nuw nsw i32 %17, 1, !dbg !48
    #dbg_value(i32 %24, !19, !DIExpression(), !36)
  %25 = icmp eq i32 %17, 0, !dbg !49
  br i1 %25, label %16, label %13, !dbg !37, !llvm.loop !50
}

declare !dbg !52 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !57 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !60 {
  %1 = tail call i32 @slice(), !dbg !61
  ret i32 %1, !dbg !62
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/loopfix/probes/n1_nested_marked_inner.c", directory: "/Users/sorenwilkening/Desktop/CQ_LOOPFIX", checksumkind: CSK_MD5, checksum: "5888874170aa99ee17343e764eb71408")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 7, type: !11, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19, !23}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 8, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 9, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 10, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 5)
!19 = !DILocalVariable(name: "j", scope: !20, file: !8, line: 12, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 12, column: 9)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 10, column: 34)
!22 = distinct !DILexicalBlock(scope: !18, file: !8, line: 10, column: 5)
!23 = !DILocalVariable(name: "u", scope: !24, file: !8, line: 13, type: !13)
!24 = distinct !DILexicalBlock(scope: !25, file: !8, line: 12, column: 37)
!25 = distinct !DILexicalBlock(scope: !20, file: !8, line: 12, column: 9)
!26 = !DILocation(line: 8, column: 13, scope: !10)
!27 = !DILocation(line: 0, scope: !10)
!28 = !DILocation(line: 0, scope: !18)
!29 = !DILocation(line: 10, column: 5, scope: !18)
!30 = !DILocation(line: 17, column: 9, scope: !10)
!31 = !DILocation(line: 18, column: 16, scope: !10)
!32 = !DILocation(line: 18, column: 14, scope: !10)
!33 = !DILocation(line: 18, column: 5, scope: !10)
!34 = !DILocation(line: 11, column: 14, scope: !21)
!35 = !DILocation(line: 11, column: 11, scope: !21)
!36 = !DILocation(line: 0, scope: !20)
!37 = !DILocation(line: 12, column: 9, scope: !20)
!38 = !DILocation(line: 10, column: 29, scope: !22)
!39 = !DILocation(line: 10, column: 23, scope: !22)
!40 = distinct !{!40, !29, !41, !42, !43}
!41 = !DILocation(line: 16, column: 5, scope: !18)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = !DILocation(line: 13, column: 21, scope: !24)
!45 = !DILocation(line: 0, scope: !24)
!46 = !DILocation(line: 14, column: 18, scope: !24)
!47 = !DILocation(line: 14, column: 15, scope: !24)
!48 = !DILocation(line: 12, column: 32, scope: !25)
!49 = !DILocation(line: 12, column: 27, scope: !25)
!50 = distinct !{!50, !37, !51, !42, !43}
!51 = !DILocation(line: 15, column: 9, scope: !20)
!52 = !DISubprogram(name: "cq_theta_si32", scope: !53, file: !53, line: 38, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!53 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_LOOPFIX", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!54 = !DISubroutineType(types: !55)
!55 = !{!13, !13, !56}
!56 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!57 = !DISubprogram(name: "cq_measure_si32", scope: !53, file: !53, line: 83, type: !58, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!58 = !DISubroutineType(types: !59)
!59 = !{!13, !13}
!60 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 20, type: !11, scopeLine: 20, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!61 = !DILocation(line: 20, column: 25, scope: !60)
!62 = !DILocation(line: 20, column: 18, scope: !60)
