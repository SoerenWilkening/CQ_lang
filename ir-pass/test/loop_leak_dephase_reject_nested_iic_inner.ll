; loop_leak_dephase_reject_nested_iic_inner.ll — DECLINE. bd
; `test_C_libtooling-emkg`, THE THIRD ROUTE: the inner loop is marked ONLY through
; bd `test_C_libtooling-tu9q`'s clause (ii-c) (the hoisted MEASURE-OWNED `y & 1`
; rail), and that marking silenced `declineDephasingUnmarkedLoopRails` for the
; enclosing OUTER loop.
;
; ⚠ A THIRD FIXTURE FOR ONE FIX IS NOT REDUNDANCY — IT IS THREE INDEPENDENT DOORS.
; The sibling `…_nested_marked_inner.ll` reaches conjunct (1) through the ROOT-MINT
; ESCAPE, `…_nested_iterlocal_inner.ll` through `markIfIterationLocal` (no track
; needed), and this file through CLAUSE (ii-c). Each marker can be changed on its
; own; a fix pinned at only one of them is pinned at none of the others.
;
; THE PROGRAM (`loopfix/probes/n3_nested_iic_inner.c`, stage-1 verbatim,
; `clang -O1 -g`):
;
;     int y = 5; cq_theta(&y, 0.5);
;     for (i = 1; i <= 2; ++i) {
;         s += cq_measure((y >> i) & 1);        // the OUTER body rail
;         for (j = 0; j < 2; ++j) {
;             int u = 6; cq_theta(&u, 0.4);
;             s += cq_measure((u >> j) & 1) + cq_measure(y & 1);   // (ii-c)
;         }
;     }
;     cq_theta(&y, 0.9);                     // the interference (Rule 8)
;     return s + cq_measure(y);
;
; `-O1` LICM-hoists the loop-invariant `y & 1`, whose every user is a
; `cq_measure`; clause (ii-c) admits exactly that rail, `markIfRailLocal` marks the
; INNER loop, and the OUTER loop exits at conjunct (1).
;
; MEASURED: LOUD DECLINE on the ORACLE `0e280fc6…`; on the merged pre-fix binary
; `ce3f8f3ddf611acc` `opt` exit 0, verify-clean, ROLLED 43 trace lines against the
; hand-unrolled twin's 48 (`n3_nested_iic_inner_un.c`). ⚠ THE DELTA IS 5, NOT 4,
; and the fifth line is a STAGE-1 fact rather than a lowering one — `-O1` CSEs the
; twin's two hoisted `y & 1` chains differently. The four that matter are the outer
; body's two `cq_template_lshr_i32_hl_unc` + `cqrt_free` pairs.
;
; ⚠ Rule 12 hygiene (b): the property is the RUN line's `not` inversion — a
; `DS_Error` decline writes 0 bytes to stdout. Validated by BINARY MUTATION.
;
; ⚠ L8 RETIREMENT TRIGGER: see `…_nested_marked_inner.ll`. Do not `git mv` this
; file.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: n3_nested_iic_inner.c:9:14: in function slice
; CHECK-SAME: cq loop lowering: rolled body leaks a rail entangled with a rotated register

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !26
    #dbg_value(i32 %1, !15, !DIExpression(), !27)
    #dbg_value(i32 0, !16, !DIExpression(), !27)
    #dbg_value(i32 1, !17, !DIExpression(), !28)
  %2 = and i32 %1, 1
  br label %7, !dbg !29

3:                                                ; preds = %14
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !30
    #dbg_value(i32 %4, !15, !DIExpression(), !27)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2, !dbg !31
  %6 = add nsw i32 %5, %26, !dbg !32
  ret i32 %6, !dbg !33

7:                                                ; preds = %0, %14
  %8 = phi i32 [ 1, %0 ], [ %15, %14 ]
  %9 = phi i32 [ 0, %0 ], [ %26, %14 ]
    #dbg_value(i32 %8, !17, !DIExpression(), !28)
    #dbg_value(i32 %9, !16, !DIExpression(), !27)
  %10 = lshr i32 %1, %8, !dbg !34
  %11 = and i32 %10, 1, !dbg !34
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !34
  %13 = add nsw i32 %12, %9, !dbg !35
    #dbg_value(i32 %13, !16, !DIExpression(), !27)
    #dbg_value(i32 0, !19, !DIExpression(), !36)
  br label %17, !dbg !37

14:                                               ; preds = %17
  %15 = add nuw nsw i32 %8, 1, !dbg !38
    #dbg_value(i32 %15, !17, !DIExpression(), !28)
    #dbg_value(i32 %26, !16, !DIExpression(), !27)
  %16 = icmp eq i32 %15, 3, !dbg !39
  br i1 %16, label %3, label %7, !dbg !29, !llvm.loop !40

17:                                               ; preds = %7, %17
  %18 = phi i32 [ 0, %7 ], [ %27, %17 ]
  %19 = phi i32 [ %13, %7 ], [ %26, %17 ]
    #dbg_value(i32 %18, !19, !DIExpression(), !36)
    #dbg_value(i32 %19, !16, !DIExpression(), !27)
  %20 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !44
    #dbg_value(i32 %20, !23, !DIExpression(), !45)
  %21 = lshr i32 %20, %18, !dbg !46
  %22 = and i32 %21, 1, !dbg !46
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #2, !dbg !46
  %24 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !47
  %25 = add i32 %23, %19, !dbg !48
  %26 = add i32 %25, %24, !dbg !49
    #dbg_value(i32 %26, !16, !DIExpression(), !27)
  %27 = add nuw nsw i32 %18, 1, !dbg !50
    #dbg_value(i32 %27, !19, !DIExpression(), !36)
  %28 = icmp eq i32 %18, 0, !dbg !51
  br i1 %28, label %17, label %14, !dbg !37, !llvm.loop !52
}

declare !dbg !54 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !59 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !62 {
  %1 = tail call i32 @slice(), !dbg !63
  ret i32 %1, !dbg !64
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/loopfix/probes/n3_nested_iic_inner.c", directory: "/Users/sorenwilkening/Desktop/CQ_LOOPFIX", checksumkind: CSK_MD5, checksum: "072b2058f05fae5ecd1d87e9fb54c98a")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19, !23}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 8, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!19 = !DILocalVariable(name: "j", scope: !20, file: !8, line: 10, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 10, column: 9)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 8, column: 34)
!22 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!23 = !DILocalVariable(name: "u", scope: !24, file: !8, line: 11, type: !13)
!24 = distinct !DILexicalBlock(scope: !25, file: !8, line: 10, column: 37)
!25 = distinct !DILexicalBlock(scope: !20, file: !8, line: 10, column: 9)
!26 = !DILocation(line: 6, column: 13, scope: !10)
!27 = !DILocation(line: 0, scope: !10)
!28 = !DILocation(line: 0, scope: !18)
!29 = !DILocation(line: 8, column: 5, scope: !18)
!30 = !DILocation(line: 15, column: 9, scope: !10)
!31 = !DILocation(line: 16, column: 16, scope: !10)
!32 = !DILocation(line: 16, column: 14, scope: !10)
!33 = !DILocation(line: 16, column: 5, scope: !10)
!34 = !DILocation(line: 9, column: 14, scope: !21)
!35 = !DILocation(line: 9, column: 11, scope: !21)
!36 = !DILocation(line: 0, scope: !20)
!37 = !DILocation(line: 10, column: 9, scope: !20)
!38 = !DILocation(line: 8, column: 29, scope: !22)
!39 = !DILocation(line: 8, column: 23, scope: !22)
!40 = distinct !{!40, !29, !41, !42, !43}
!41 = !DILocation(line: 14, column: 5, scope: !18)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = !DILocation(line: 11, column: 21, scope: !24)
!45 = !DILocation(line: 0, scope: !24)
!46 = !DILocation(line: 12, column: 18, scope: !24)
!47 = !DILocation(line: 12, column: 45, scope: !24)
!48 = !DILocation(line: 12, column: 43, scope: !24)
!49 = !DILocation(line: 12, column: 15, scope: !24)
!50 = !DILocation(line: 10, column: 32, scope: !25)
!51 = !DILocation(line: 10, column: 27, scope: !25)
!52 = distinct !{!52, !37, !53, !42, !43}
!53 = !DILocation(line: 13, column: 9, scope: !20)
!54 = !DISubprogram(name: "cq_theta_si32", scope: !55, file: !55, line: 38, type: !56, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_LOOPFIX", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!56 = !DISubroutineType(types: !57)
!57 = !{!13, !13, !58}
!58 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!59 = !DISubprogram(name: "cq_measure_si32", scope: !55, file: !55, line: 83, type: !60, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!60 = !DISubroutineType(types: !61)
!61 = !{!13, !13}
!62 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 18, type: !11, scopeLine: 18, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!63 = !DILocation(line: 18, column: 25, scope: !62)
!64 = !DILocation(line: 18, column: 18, scope: !62)
