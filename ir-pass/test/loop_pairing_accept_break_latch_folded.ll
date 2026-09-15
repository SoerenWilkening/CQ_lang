; loop_pairing_accept_break_latch_folded.ll — ACCEPT. bd
; `test_C_libtooling-tu9q`'s IN-LOOP PAIRING INSIDE A 7.4 `break` LOOP, and the
; ONE cell in that increment that HAS NO HAND-UNROLLED TWIN. It is pinned here
; with a **TRANSFER WITNESS** obtained by decomposition, and the header says
; exactly what was and was not compared — a `CLAUDE.md` §5 lesson, where a shipped
; fixture family read a STABILITY measurement as a CORRECTNESS one.
;
; THE PROGRAM (`trackT/probes/adv/r1_break_loop.c`, stage-1 verbatim, `-O1 -g`):
;
;     int y = cq_theta(5, 0.5);
;     for (k = 1; k <= 4; ++k) {
;         s += cq_measure((y >> k) & 1);
;         if (s > 1) break;                 // the 7.4 classical exit
;     }
;     y = cq_theta(y, 0.9);
;     return s + cq_measure(y);
;
; ⚠ WHY THE ORDINARY WITNESS IS UNAVAILABLE, MEASURED RATHER THAN ASSERTED. The
; hand-unrolled spelling of a `break` loop is a nested-`if` cascade, and that
; cascade is a LOUD DECLINE at bd `test_C_libtooling-3d8q`'s stale-reader fence
; (`cq opcode lowering: operand predates a non-diagonal gate`) on EVERY binary
; tried — ORACLE `0e280fc6…`, Track S′, Track T, and the merged binary. A
; split-body variant built specifically to defeat `-O1`'s if-conversion
; (`loopfix/probes/t5b_break_split.c`, a second gate group after the break test)
; declines at the SAME fence on all of them. So the class cannot be witnessed the
; usual way, and saying "no witness" and shipping anyway would be the thing this
; project does not do.
;
; THE TRANSFER WITNESS, IN THREE MEASURED STEPS (merged binary `9dd81edb9f949bb5`):
;   (1) `-O1` IF-CONVERTS the `break` into one extra disjunct on the **LATCH**
;       predicate, so the whole body is a SINGLE BASIC BLOCK — read it below:
;       `@slice`'s block `%1` holds the mint, the second mint, the `_unc`, the
;       `cqrt_free` and the `cqrt_measure_i32`, and the only branch is the latch
;       `br i1 %8`. The per-trip group is therefore ATOMIC BY CONSTRUCTION and
;       1:1 by construction: the `break` can only stop the sequence AT A GROUP
;       BOUNDARY, never between a mint and its adjoint.
;   (2) The break-free twin of the same body — `loopfix/probes/t5a_nobreak.c`,
;       identical apart from the deleted `if (s > 1) break;` — DOES have a usable
;       hand-unrolled twin, and it is **24 == 24, `diff` EMPTY, BYTE-IDENTICAL**.
;   (3) `diff r1_break_loop.trace t5a_nobreak.trace` is **EMPTY** — this program's
;       emitted gate stream IS that program's stream, byte for byte, 24 lines.
; So the stream shipped here is the stream of a program whose rolled form is
; byte-identical to its hand-unrolled twin. ⚠ **THAT IS A WITNESS OF THE SAME KIND
; THE CLASS USES, OBTAINED BY DECOMPOSITION — IT IS NOT A TWIN**, and the
; difference is not cosmetic: it transfers only because steps (1) and (3) hold
; together. If either moves, the witness is gone.
;
; ⚠ WHAT IS **NOT** CLAIMED. Multi-exit shapes were NOT exhausted. The structural
; argument that covers them — a discharge in a block the `break` could skip is
; dominated by its mint, so `discharge ⇒ mint ran`, and the converse cannot occur
; because a free point must be dominated by its def — holds where it was checked,
; but the reachable counter-shapes die at bd `3d8q` FIRST, and that is **a
; measurement about today's binary, not a proof**. ⚠ AND NO MULTI-EXIT REFUSAL WAS
; ADDED, DELIBERATELY (Rule 17, owner 2026-09-11): it would be an over-decline on
; an argument nobody can substantiate in either direction, and it would refuse a
; program there IS a witness for.
;
; ⚠ L8 RETIREMENT TRIGGER, BY NAME: **when bd `test_C_libtooling-3d8q`'s fence
; stops refusing the nested-`if` cascade, a REAL hand-unrolled twin becomes
; constructible — build it and re-derive this cell**, and replace the transfer
; witness above with the direct one. A second trigger: if `-O1` ever stops folding
; this `break` into the latch, the body is no longer one block, step (1) is gone
; and the whole witness must be rebuilt. The `CHECK-NEXT` chain below is what
; detects that — it is pinning the ATOMICITY, not just the symbols.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UNCCOUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FREECOUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; THE ATOMIC PER-TRIP GROUP — mint, mint, ADJOINT, FREE, measure, CONSECUTIVE.
; CHECK-LABEL: define i32 @slice
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; CHECK: %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %{{[0-9]+}})
; CHECK-NEXT: %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1)
; CHECK-NEXT: call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
; CHECK-NEXT: %m{{[0-9]*}} = call i32 @cqrt_measure_i32(i32 %h_op1)
; and the interference AFTER the loop, on the register those rails copy:
; CHECK: call void @cqrt_ry_i32(i32 %h, double 9.000000e-01)
;
; ⚠ THE TRAILING LABEL IS LOAD-BEARING: `-O1` inlines `@slice` into `@main`, so
; the module carries TWO copies of this stream and without a second `CHECK-LABEL`
; every positive above can be satisfied by the `@main` copy (bd
; `test_C_libtooling-1yeu` — the second function is a DECOY, not a spare).
; CHECK-LABEL: define i32 @main
;
; WHOLE-FILE COUNTS, ONE COUNTED SYMBOL PER PREFIX, NEGATIVES SOMEWHERE ELSE
; ENTIRELY (Rule 12 fixture-hygiene defect (a): a positive `CHECK-COUNT` above a
; negative WINDOWS it — reproduced independently by THREE tracks in session
; 2026-09-15). ROLLED, two functions, so exactly one pair each.
; UNCCOUNT-COUNT-2: call void @cq_template_lshr_i32_hl_unc(
; UNCCOUNT-NOT: call void @cq_template_lshr_i32_hl_unc(
;
; FREECOUNT-COUNT-2: call void @cqrt_free(
; FREECOUNT-NOT: call void @cqrt_free(
;
; PURE NEGATIVES — never a free of the user's register, never a free of the
; measure-owned `and` rail, never an adjoint of it, and no decline text.
; NEG-NOT: call void @cqrt_free(i32 %h)
; NEG-NOT: call void @cqrt_free(i32 %h_op1)
; NEG-NOT: call void @cq_template_and_i32_hl_unc(
; NEG-NOT: rolled body leaks a rail
; NEG-NOT: predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !19
    #dbg_value(i32 %1, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 1, !17, !DIExpression(), !21)
  br label %2, !dbg !22

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %10, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %8, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !21)
    #dbg_value(i32 %4, !16, !DIExpression(), !20)
  %5 = lshr i32 %1, %3, !dbg !23
  %6 = and i32 %5, 1, !dbg !23
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !23
  %8 = add nsw i32 %7, %4, !dbg !26
    #dbg_value(i32 %8, !16, !DIExpression(), !20)
  %9 = icmp sgt i32 %8, 1, !dbg !27
    #dbg_value(i32 %3, !17, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !21)
  %10 = add nuw nsw i32 %3, 1
    #dbg_value(i32 %10, !17, !DIExpression(), !21)
    #dbg_value(i32 %10, !17, !DIExpression(), !21)
    #dbg_value(i32 %8, !16, !DIExpression(), !20)
  %11 = icmp eq i32 %10, 5
  %12 = select i1 %9, i1 true, i1 %11, !dbg !29
  br i1 %12, label %13, label %2, !dbg !29, !llvm.loop !30

13:                                               ; preds = %2
    #dbg_value(i32 %8, !16, !DIExpression(), !20)
  %14 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !34
    #dbg_value(i32 %14, !15, !DIExpression(), !20)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2, !dbg !35
  %16 = add nsw i32 %15, %8, !dbg !36
  ret i32 %16, !dbg !37
}

declare !dbg !38 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !43 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !46 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !47
    #dbg_value(i32 %1, !15, !DIExpression(), !49)
    #dbg_value(i32 0, !16, !DIExpression(), !49)
    #dbg_value(i32 1, !17, !DIExpression(), !50)
  br label %2, !dbg !51

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %10, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %8, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !50)
    #dbg_value(i32 %4, !16, !DIExpression(), !49)
  %5 = lshr i32 %1, %3, !dbg !52
  %6 = and i32 %5, 1, !dbg !52
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !52
  %8 = add nsw i32 %7, %4, !dbg !53
    #dbg_value(i32 %8, !16, !DIExpression(), !49)
  %9 = icmp sgt i32 %8, 1, !dbg !54
    #dbg_value(i32 %3, !17, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !50)
  %10 = add nuw nsw i32 %3, 1
    #dbg_value(i32 %10, !17, !DIExpression(), !50)
    #dbg_value(i32 %10, !17, !DIExpression(), !50)
    #dbg_value(i32 %8, !16, !DIExpression(), !49)
  %11 = icmp eq i32 %10, 5
  %12 = select i1 %9, i1 true, i1 %11, !dbg !55
  br i1 %12, label %13, label %2, !dbg !55, !llvm.loop !56

13:                                               ; preds = %2
    #dbg_value(i32 %8, !16, !DIExpression(), !49)
  %14 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !58
    #dbg_value(i32 %14, !15, !DIExpression(), !49)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2, !dbg !59
  %16 = add nsw i32 %15, %8, !dbg !60
  ret i32 %16, !dbg !61
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r1_break_loop.c", directory: "/Users/sorenwilkening/Desktop/CQ_LOOPFIX", checksumkind: CSK_MD5, checksum: "b9060f20c4039ae54c1c27f7090e5d0c")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 8, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!19 = !DILocation(line: 6, column: 13, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 8, column: 5, scope: !18)
!23 = !DILocation(line: 9, column: 14, scope: !24)
!24 = distinct !DILexicalBlock(scope: !25, file: !8, line: 8, column: 34)
!25 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!26 = !DILocation(line: 9, column: 11, scope: !24)
!27 = !DILocation(line: 10, column: 15, scope: !28)
!28 = distinct !DILexicalBlock(scope: !24, file: !8, line: 10, column: 13)
!29 = !DILocation(line: 10, column: 13, scope: !24)
!30 = distinct !{!30, !22, !31, !32, !33}
!31 = !DILocation(line: 11, column: 5, scope: !18)
!32 = !{!"llvm.loop.mustprogress"}
!33 = !{!"llvm.loop.unroll.disable"}
!34 = !DILocation(line: 12, column: 9, scope: !10)
!35 = !DILocation(line: 13, column: 16, scope: !10)
!36 = !DILocation(line: 13, column: 14, scope: !10)
!37 = !DILocation(line: 13, column: 5, scope: !10)
!38 = !DISubprogram(name: "cq_theta_si32", scope: !39, file: !39, line: 38, type: !40, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!39 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_LOOPFIX", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!40 = !DISubroutineType(types: !41)
!41 = !{!13, !13, !42}
!42 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!43 = !DISubprogram(name: "cq_measure_si32", scope: !39, file: !39, line: 83, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DISubroutineType(types: !45)
!45 = !{!13, !13}
!46 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!47 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !48)
!48 = distinct !DILocation(line: 15, column: 25, scope: !46)
!49 = !DILocation(line: 0, scope: !10, inlinedAt: !48)
!50 = !DILocation(line: 0, scope: !18, inlinedAt: !48)
!51 = !DILocation(line: 8, column: 5, scope: !18, inlinedAt: !48)
!52 = !DILocation(line: 9, column: 14, scope: !24, inlinedAt: !48)
!53 = !DILocation(line: 9, column: 11, scope: !24, inlinedAt: !48)
!54 = !DILocation(line: 10, column: 15, scope: !28, inlinedAt: !48)
!55 = !DILocation(line: 10, column: 13, scope: !24, inlinedAt: !48)
!56 = distinct !{!56, !51, !57, !32, !33}
!57 = !DILocation(line: 11, column: 5, scope: !18, inlinedAt: !48)
!58 = !DILocation(line: 12, column: 9, scope: !10, inlinedAt: !48)
!59 = !DILocation(line: 13, column: 16, scope: !10, inlinedAt: !48)
!60 = !DILocation(line: 13, column: 14, scope: !10, inlinedAt: !48)
!61 = !DILocation(line: 15, column: 18, scope: !46)
