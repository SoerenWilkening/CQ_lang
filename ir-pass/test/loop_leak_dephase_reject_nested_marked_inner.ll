; loop_leak_dephase_reject_nested_marked_inner.ll — DECLINE. bd
; `test_C_libtooling-emkg`: `declineDephasingUnmarkedLoopRails`' conjunct (1) used
; to ask *"is this loop's body marked iteration-local?"* over `L->blocks()`, WHICH
; INCLUDES EVERY STRICTLY-DEEPER SUBLOOP'S BLOCKS, while conjunct (3) asked its
; question over `L`'s OWN blocks only. A marked INNER loop therefore SILENCED the
; whole fence for its enclosing OUTER loop, whose own per-trip rails still leaked.
; Found by Rule-13 round 2 of 2026-09-15 (`review_r13_loop/REVIEW.md` F-1), P1
; OVER-ACCEPT; this file is the face that was a REGRESSION rather than a
; pre-existing hole — see the sibling `…_nested_iterlocal_inner.ll` for the
; pre-existing one.
;
; THE PROGRAM (`loopfix/probes/n2_nested_unmarked_inner.c`, stage-1 verbatim,
; `clang -O1 -g`):
;
;     int y = 5; cq_theta(&y, 0.5);
;     for (i = 1; i <= 2; ++i) {
;         s += cq_measure((y >> i) & 1);            // the OUTER body rail
;         for (j = 0; j < 2; ++j)
;             s += cq_measure((y >> (j + 8)) & 1);  // the INNER body
;     }
;     cq_theta(&y, 0.9);                         // the interference (Rule 8)
;     return s + cq_measure(y);
;
; WHY IT IS A REGRESSION AND NOT A PRE-EXISTING HOLE. On the 2026-09-15 ORACLE
; `0e280fc6…` this module is a LOUD DECLINE: nothing marks the inner loop there,
; so conjunct (1) is false and conjunct (3) reaches the outer body's `lshr`. bd
; `test_C_libtooling-tu9q`'s ROOT-MINT ESCAPE then made `invariantRegisterRoots`
; admit `y`'s root mint, `markIfRailLocal` marked the INNER loop — and the OUTER
; loop left the fence at conjunct (1), on a marking that says nothing about it.
; MEASURED on the merged pre-fix binary `ce3f8f3ddf611acc`: `opt` exit 0,
; verify-clean, ROLLED 30 trace lines against the hand-unrolled twin's 34
; (`n2_nested_unmarked_inner_un.c`, the OUTER loop unrolled and the inner left
; rolled). The four missing lines are the outer body's two
; `cq_template_lshr_i32_hl_unc` + `cqrt_free` pairs — undischarged WHICH-PATH
; COPIES of `y` standing at `cqrt_ry_i32(h0, 0.9)`. Rolled and unrolled are
; DIFFERENT UNITARIES (`CLAUDE.md` Rule 8: *a permutation that leaves a rail dirty
; AND entangled still dephases under later interference*), at `opt` exit 0 and
; verify-clean — the bd `test_C_libtooling-s82e` DIVERGENT class.
;
; THE FIX IS A SHARED PREDICATE, NOT A THIRD SPELLING (Rule 14 / `CLAUDE.md` L2).
; `declineUnmarkedRolledIterLocal` has always skipped `LI.getLoopFor(BB) != L`
; with the comment *"a strictly-deeper subloop's block — not `L`'s to mark"*;
; `bodyBlocksMarked` is now that one spelling and both sites CALL it.
;
; ⚠ WHY THE IR-TEXT PROPERTY IS THE `not` INVERSION AND NOTHING ELSE (Rule 12
; fixture-hygiene defect (b)): a `DS_Error` decline writes 0 BYTES to stdout, so a
; `CHECK-NOT` over the lowered module here would be VACUOUS. The RUN line's `not`
; is the pin. Validated by BINARY MUTATION: on the pre-fix binary this file does
; NOT pass (`opt` exits 0 and FileCheck sees no diagnostic).
;
; ⚠ THE LOCATION IS PINNED, NOT JUST THE STRING. A diagnostic that loses its
; `!dbg` prints `<unknown>:0:0` and is invisible to every gate in this tree except
; a full-stderr compare (Track P, 2026-09-14). The anchor is the OUTER body's
; rail-minting instruction — the line the user has to change.
;
; ⚠ L8 RETIREMENT TRIGGER: if the in-loop pairing is ever widened to DISCHARGE an
; outer loop's own per-trip rails when a subloop is marked, this program becomes an
; ACCEPT whose rolled stream is the 34-line twin's. Re-derive it then — do not
; delete it, and do not `git mv` it (bd `test_C_libtooling-gahu`, `CLAUDE.md` L8: a
; renamed fixture can be RESURRECTED by a merge).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: n2_nested_unmarked_inner.c:10:14: in function slice
; CHECK-SAME: cq loop lowering: rolled body leaks a rail entangled with a rotated register

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !23
    #dbg_value(i32 %1, !15, !DIExpression(), !24)
    #dbg_value(i32 0, !16, !DIExpression(), !24)
    #dbg_value(i32 1, !17, !DIExpression(), !25)
  br label %6, !dbg !26

2:                                                ; preds = %13
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !27
    #dbg_value(i32 %3, !15, !DIExpression(), !24)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !28
  %5 = add nsw i32 %4, %23, !dbg !29
  ret i32 %5, !dbg !30

6:                                                ; preds = %0, %13
  %7 = phi i32 [ 1, %0 ], [ %14, %13 ]
  %8 = phi i32 [ 0, %0 ], [ %23, %13 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !25)
    #dbg_value(i32 %8, !16, !DIExpression(), !24)
  %9 = lshr i32 %1, %7, !dbg !31
  %10 = and i32 %9, 1, !dbg !31
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !31
  %12 = add nsw i32 %11, %8, !dbg !32
    #dbg_value(i32 %12, !16, !DIExpression(), !24)
    #dbg_value(i32 0, !19, !DIExpression(), !33)
  br label %16, !dbg !34

13:                                               ; preds = %16
  %14 = add nuw nsw i32 %7, 1, !dbg !35
    #dbg_value(i32 %14, !17, !DIExpression(), !25)
    #dbg_value(i32 %23, !16, !DIExpression(), !24)
  %15 = icmp eq i32 %14, 3, !dbg !36
  br i1 %15, label %2, label %6, !dbg !26, !llvm.loop !37

16:                                               ; preds = %6, %16
  %17 = phi i32 [ 0, %6 ], [ %24, %16 ]
  %18 = phi i32 [ %12, %6 ], [ %23, %16 ]
    #dbg_value(i32 %17, !19, !DIExpression(), !33)
    #dbg_value(i32 %18, !16, !DIExpression(), !24)
  %19 = or disjoint i32 %17, 8, !dbg !41
  %20 = lshr i32 %1, %19, !dbg !41
  %21 = and i32 %20, 1, !dbg !41
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #2, !dbg !41
  %23 = add nsw i32 %22, %18, !dbg !43
    #dbg_value(i32 %23, !16, !DIExpression(), !24)
  %24 = add nuw nsw i32 %17, 1, !dbg !44
    #dbg_value(i32 %24, !19, !DIExpression(), !33)
  %25 = icmp eq i32 %17, 0, !dbg !45
  br i1 %25, label %16, label %13, !dbg !34, !llvm.loop !46
}

declare !dbg !48 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !53 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !56 {
  %1 = tail call i32 @slice(), !dbg !57
  ret i32 %1, !dbg !58
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/loopfix/probes/n2_nested_unmarked_inner.c", directory: "/Users/sorenwilkening/Desktop/CQ_LOOPFIX", checksumkind: CSK_MD5, checksum: "95687fcea2cc0213cc7a06c4fd7897a8")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 9, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!19 = !DILocalVariable(name: "j", scope: !20, file: !8, line: 11, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 11, column: 9)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 9, column: 34)
!22 = distinct !DILexicalBlock(scope: !18, file: !8, line: 9, column: 5)
!23 = !DILocation(line: 7, column: 13, scope: !10)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 0, scope: !18)
!26 = !DILocation(line: 9, column: 5, scope: !18)
!27 = !DILocation(line: 14, column: 9, scope: !10)
!28 = !DILocation(line: 15, column: 16, scope: !10)
!29 = !DILocation(line: 15, column: 14, scope: !10)
!30 = !DILocation(line: 15, column: 5, scope: !10)
!31 = !DILocation(line: 10, column: 14, scope: !21)
!32 = !DILocation(line: 10, column: 11, scope: !21)
!33 = !DILocation(line: 0, scope: !20)
!34 = !DILocation(line: 11, column: 9, scope: !20)
!35 = !DILocation(line: 9, column: 29, scope: !22)
!36 = !DILocation(line: 9, column: 23, scope: !22)
!37 = distinct !{!37, !26, !38, !39, !40}
!38 = !DILocation(line: 13, column: 5, scope: !18)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !{!"llvm.loop.unroll.disable"}
!41 = !DILocation(line: 12, column: 18, scope: !42)
!42 = distinct !DILexicalBlock(scope: !20, file: !8, line: 11, column: 9)
!43 = !DILocation(line: 12, column: 15, scope: !42)
!44 = !DILocation(line: 11, column: 32, scope: !42)
!45 = !DILocation(line: 11, column: 27, scope: !42)
!46 = distinct !{!46, !34, !47, !39, !40}
!47 = !DILocation(line: 12, column: 18, scope: !20)
!48 = !DISubprogram(name: "cq_theta_si32", scope: !49, file: !49, line: 38, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!49 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_LOOPFIX", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!50 = !DISubroutineType(types: !51)
!51 = !{!13, !13, !52}
!52 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!53 = !DISubprogram(name: "cq_measure_si32", scope: !49, file: !49, line: 83, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!54 = !DISubroutineType(types: !55)
!55 = !{!13, !13}
!56 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 17, type: !11, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!57 = !DILocation(line: 17, column: 25, scope: !56)
!58 = !DILocation(line: 17, column: 18, scope: !56)
