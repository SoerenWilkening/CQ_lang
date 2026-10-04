; loop_leak_dephase_reject_nested_depth3_middle_rail.ll — DECLINE. bd
; `test_C_libtooling-emkg` AT DEPTH THREE, and **THE MOST INSTRUCTIVE CELL OF THE
; FOUR** because the instrument this class is normally read with — the
; rolled-vs-hand-unrolled TRACE LINE COUNT — reports **72 against 72 and is
; WRONG**.
;
; ⚠ THIS FILE EXISTS BECAUSE THE FIX'S OWN RULE-13 RE-ATTACK FOUND IT, not because
; the review asked for it. It was built to test whether a three-level nest
; over-declines after the conjunct-(1) narrowing; the first measurement read
; `ORA A:72 | twin A:72` and looked exactly like an over-decline this fix had
; introduced. The MULTISET said otherwise.
;
; THE PROGRAM (`loopfix/probes/r1_triple_nest_mid_rail.c`, stage-1 verbatim,
; `clang -O1 -g`):
;
;     int y = 5; cq_theta(&y, 0.5);
;     for (i = 0; i < 2; ++i)
;         for (j = 1; j <= 2; ++j) {
;             s += cq_measure((y >> j) & 1);        // the MIDDLE loop's OWN rail
;             for (k = 0; k < 2; ++k) {             // fully ITERATION-LOCAL
;                 int u = 6; cq_theta(&u, 0.4);
;                 s += cq_measure((u >> k) & 1);
;             }
;         }
;     cq_theta(&y, 0.9);                         // the interference (Rule 8)
;     return s + cq_measure(y);
;
; `markIfIterationLocal` marks the INNERMOST loop; before the fix, conjunct (1)
; saw one of its blocks in `L_middle->blocks()` and the MIDDLE loop — whose own
; body mints `(y >> j) & 1`, a which-path copy of `y` — was never examined. The
; OUTERMOST loop has no rail-minting op of its own and accepts either way; it is
; in the program so the fix is exercised at TWO nesting levels at once.
;
; ⚠⚠ **WHAT THE MEASUREMENT ACTUALLY SAYS, AND WHY THE LINE COUNT LIES.** On the
; ORACLE `0e280fc6…` and on the pre-fix merged binary `ce3f8f3ddf611acc` this
; module ACCEPTS, and the hand-unrolled twin (`…_un.c`, the MIDDLE loop unrolled,
; outer and inner left rolled) also emits **72 lines**. Equal. The gate-symbol
; MULTISET is not:
;
;     rolled                              twin
;       12 cq_template_and_i32_hl            10 cq_template_and_i32_hl
;       12 cq_template_lshr_i32_hl           10 cq_template_lshr_i32_hl
;        8 cq_template_lshr_i32_hl_unc       10 cq_template_lshr_i32_hl_unc
;        8 cqrt_free                         10 cqrt_free
;
; The rolled form mints TWELVE rails and discharges EIGHT — **four undischarged
; which-path copies of `y`**, one per middle-loop trip — while the twin mints ten
; (`-O1` CSEs two of its chains) and discharges all ten. `12 + 12 + 8 + 8` and
; `10 + 10 + 10 + 10` are both 40, which is the entire reason the totals agree.
; ⚠ `CLAUDE.md` §5 records a shipped fixture family whose header read a STABILITY
; measurement as a CORRECTNESS one; this is the same error one instrument over —
; **a LINE-COUNT equality is not a multiset equality, and for a NESTED loop it is
; not even good evidence of one.** Compare multisets, or compare bytes.
;
; MEASURED after the fix (`9dd81edb9f949bb5`): LOUD DECLINE, anchored at the
; middle loop's own rail-minting instruction.
;
; ⚠ Rule 12 hygiene (b): a `DS_Error` decline writes 0 BYTES to stdout, so the
; property is the RUN line's `not` inversion. Validated by BINARY MUTATION — this
; file does NOT pass on the pre-fix binary, where `opt` exits 0.
;
; ⚠ L8 RETIREMENT TRIGGER: same as the three depth-2 siblings — if the pairing is
; widened to discharge a middle loop's own per-trip rails, this becomes an ACCEPT
; whose rolled multiset matches the twin's. Re-derive it then; do not delete it,
; and do not `git mv` it (bd `test_C_libtooling-gahu`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: r1_triple_nest_mid_rail.c:11:18: in function slice
; CHECK-SAME: cq loop lowering: rolled body leaks a rail entangled with a rotated register

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !29
    #dbg_value(i32 %1, !15, !DIExpression(), !30)
    #dbg_value(i32 0, !16, !DIExpression(), !30)
    #dbg_value(i32 0, !17, !DIExpression(), !31)
  br label %2, !dbg !32

2:                                                ; preds = %0, %9
  %3 = phi i32 [ 0, %0 ], [ %10, %9 ]
  %4 = phi i32 [ 0, %0 ], [ %29, %9 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !31)
    #dbg_value(i32 %4, !16, !DIExpression(), !30)
    #dbg_value(i32 1, !19, !DIExpression(), !33)
    #dbg_value(i32 %4, !16, !DIExpression(), !30)
  br label %12, !dbg !34

5:                                                ; preds = %9
  %6 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !35
    #dbg_value(i32 %6, !15, !DIExpression(), !30)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !36
  %8 = add nsw i32 %7, %29, !dbg !37
  ret i32 %8, !dbg !38

9:                                                ; preds = %19
  %10 = add nuw nsw i32 %3, 1, !dbg !39
    #dbg_value(i32 %10, !17, !DIExpression(), !31)
    #dbg_value(i32 %29, !16, !DIExpression(), !30)
  %11 = icmp eq i32 %3, 0, !dbg !40
  br i1 %11, label %2, label %5, !dbg !32, !llvm.loop !41

12:                                               ; preds = %2, %19
  %13 = phi i32 [ 1, %2 ], [ %20, %19 ]
  %14 = phi i32 [ %4, %2 ], [ %29, %19 ]
    #dbg_value(i32 %13, !19, !DIExpression(), !33)
    #dbg_value(i32 %14, !16, !DIExpression(), !30)
  %15 = lshr i32 %1, %13, !dbg !45
  %16 = and i32 %15, 1, !dbg !45
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #2, !dbg !45
  %18 = add nsw i32 %17, %14, !dbg !46
    #dbg_value(i32 %18, !16, !DIExpression(), !30)
    #dbg_value(i32 0, !22, !DIExpression(), !47)
  br label %22, !dbg !48

19:                                               ; preds = %22
  %20 = add nuw nsw i32 %13, 1, !dbg !49
    #dbg_value(i32 %20, !19, !DIExpression(), !33)
    #dbg_value(i32 %29, !16, !DIExpression(), !30)
  %21 = icmp eq i32 %20, 3, !dbg !50
  br i1 %21, label %9, label %12, !dbg !34, !llvm.loop !51

22:                                               ; preds = %12, %22
  %23 = phi i32 [ 0, %12 ], [ %30, %22 ]
  %24 = phi i32 [ %18, %12 ], [ %29, %22 ]
    #dbg_value(i32 %23, !22, !DIExpression(), !47)
    #dbg_value(i32 %24, !16, !DIExpression(), !30)
  %25 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !53
    #dbg_value(i32 %25, !26, !DIExpression(), !54)
  %26 = lshr i32 %25, %23, !dbg !55
  %27 = and i32 %26, 1, !dbg !55
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #2, !dbg !55
  %29 = add nsw i32 %28, %24, !dbg !56
    #dbg_value(i32 %29, !16, !DIExpression(), !30)
  %30 = add nuw nsw i32 %23, 1, !dbg !57
    #dbg_value(i32 %30, !22, !DIExpression(), !47)
  %31 = icmp eq i32 %23, 0, !dbg !58
  br i1 %31, label %22, label %19, !dbg !48, !llvm.loop !59
}

declare !dbg !61 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !66 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !69 {
  %1 = tail call i32 @slice(), !dbg !70
  ret i32 %1, !dbg !71
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/loopfix/probes/r1_triple_nest_mid_rail.c", directory: "/Users/sorenwilkening/Desktop/CQ_LOOPFIX", checksumkind: CSK_MD5, checksum: "c6349ed1d3a365097494d4e09610b406")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19, !22, !26}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 9, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!19 = !DILocalVariable(name: "j", scope: !20, file: !8, line: 10, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 10, column: 9)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 9, column: 5)
!22 = !DILocalVariable(name: "k", scope: !23, file: !8, line: 12, type: !13)
!23 = distinct !DILexicalBlock(scope: !24, file: !8, line: 12, column: 13)
!24 = distinct !DILexicalBlock(scope: !25, file: !8, line: 10, column: 38)
!25 = distinct !DILexicalBlock(scope: !20, file: !8, line: 10, column: 9)
!26 = !DILocalVariable(name: "u", scope: !27, file: !8, line: 13, type: !13)
!27 = distinct !DILexicalBlock(scope: !28, file: !8, line: 12, column: 41)
!28 = distinct !DILexicalBlock(scope: !23, file: !8, line: 12, column: 13)
!29 = !DILocation(line: 7, column: 13, scope: !10)
!30 = !DILocation(line: 0, scope: !10)
!31 = !DILocation(line: 0, scope: !18)
!32 = !DILocation(line: 9, column: 5, scope: !18)
!33 = !DILocation(line: 0, scope: !20)
!34 = !DILocation(line: 10, column: 9, scope: !20)
!35 = !DILocation(line: 17, column: 9, scope: !10)
!36 = !DILocation(line: 18, column: 16, scope: !10)
!37 = !DILocation(line: 18, column: 14, scope: !10)
!38 = !DILocation(line: 18, column: 5, scope: !10)
!39 = !DILocation(line: 9, column: 28, scope: !21)
!40 = !DILocation(line: 9, column: 23, scope: !21)
!41 = distinct !{!41, !32, !42, !43, !44}
!42 = !DILocation(line: 16, column: 9, scope: !18)
!43 = !{!"llvm.loop.mustprogress"}
!44 = !{!"llvm.loop.unroll.disable"}
!45 = !DILocation(line: 11, column: 18, scope: !24)
!46 = !DILocation(line: 11, column: 15, scope: !24)
!47 = !DILocation(line: 0, scope: !23)
!48 = !DILocation(line: 12, column: 13, scope: !23)
!49 = !DILocation(line: 10, column: 33, scope: !25)
!50 = !DILocation(line: 10, column: 27, scope: !25)
!51 = distinct !{!51, !34, !52, !43, !44}
!52 = !DILocation(line: 16, column: 9, scope: !20)
!53 = !DILocation(line: 13, column: 25, scope: !27)
!54 = !DILocation(line: 0, scope: !27)
!55 = !DILocation(line: 14, column: 22, scope: !27)
!56 = !DILocation(line: 14, column: 19, scope: !27)
!57 = !DILocation(line: 12, column: 36, scope: !28)
!58 = !DILocation(line: 12, column: 31, scope: !28)
!59 = distinct !{!59, !48, !60, !43, !44}
!60 = !DILocation(line: 15, column: 13, scope: !23)
!61 = !DISubprogram(name: "cq_theta_si32", scope: !62, file: !62, line: 38, type: !63, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!62 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_LOOPFIX", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!63 = !DISubroutineType(types: !64)
!64 = !{!13, !13, !65}
!65 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!66 = !DISubprogram(name: "cq_measure_si32", scope: !62, file: !62, line: 83, type: !67, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!67 = !DISubroutineType(types: !68)
!68 = !{!13, !13}
!69 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 20, type: !11, scopeLine: 20, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!70 = !DILocation(line: 20, column: 25, scope: !69)
!71 = !DILocation(line: 20, column: 18, scope: !69)
