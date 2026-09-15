; loop_leak_dephase_reject_noregion_live.ll — ⚠ THE NAME IS HISTORY: THIS FILE IS
; NOW AN **ACCEPT**. bd `test_C_libtooling-tu9q` (the IN-LOOP PAIRING) landed
; 2026-09-15 and retired the bd `test_C_libtooling-s82e` / owner-ruling-D4 decline
; this file used to pin. The retirement trigger the previous header carried was
; character-for-character correct and is quoted here so the next reader can see
; that it fired rather than re-deriving it:
;
;     "When `tu9q` lands this file becomes an ACCEPT whose stream is the 14-line
;      hand-unrolled twin's, rolled — re-derive it then; do not delete it."
;
; ⚠ IT IS NOT RENAMED, DELIBERATELY (bd `test_C_libtooling-gahu`, `CLAUDE.md` L8):
; a `git mv`'d fixture can be RESURRECTED by a merge, leaving one module under two
; names with contradictory verdicts and invisible to every review that ran before
; the merge. Renaming is owed as its own change, after this one has merged.
;
; THE PROGRAM (`trackS/probes/s1_live_shift.c`, stage-1 verbatim, `-O1 -g`):
;
;     int y = cq_theta(5, 0.5);
;     for (k = 1; k <= 2; ++k) s += cq_measure((y >> k) & 1);
;     y = cq_theta(y, 0.9);                 // the interference
;     return s + cq_measure(y);
;
; WHAT CHANGED, AND IT IS A CAPABILITY AND NOT A RELAXED FENCE. `-O1` leaves `y`
; loop-INVARIANT and the body mints a per-trip `cq_template_lshr_i32_hl` rail — a
; which-path copy of `y`'s qubits. `markIfIterationLocal` refused to mark the body
; because it reads a tainted value defined OUTSIDE the loop, and that refusal is a
; LEAK, not a decline: the spine's in-loop guard then skipped the rail and emitted
; neither `_unc` nor `cqrt_free`, while the HAND-UNROLLED spelling of the same
; source emits both. The D4 decline existed because that is a WRONG UNITARY where
; the copied register is re-rotated afterwards (Rule 8).
;
; `lowerLoops` now offers the loop `markIfRailLocal` — the SIBLING marker, which
; already had the `Roots` escape, and `invariantRegisterRoots`, which already owned
; the proof that a ROOT MINT is sound to put in that set. Both were built for the
; ROUND-2 region path, and `collapseFlattenedLoopRails` opens
; `if (taint.InLoopFlattenedPreds.empty()) return;` — so for a loop with NO TAINTED
; CONTROL FLOW AT ALL they never ran. `CLAUDE.md` L2: one of the two sibling
; clauses was widened and the other was left.
;
; MEASURED on the subject, against the ORACLE `0e280fc6…` where this module is a
; loud DECLINE: `opt` exit 0, verify-clean, the rolled trace is **14 lines and
; BYTE-IDENTICAL to the hand-unrolled twin's** (`trackT/probes/out/`), and STRICT
; stage 2b reports `2 rail mint(s) of which 2 left allocated, 2 cqrt_free site(s):
; 2 verified, 0 violation(s), 0 unproven`.
;
; ⚠ 2b IS NOT THE WITNESS HERE AND NEVER WAS. It counts `cqrt_alloc` SITES, and the
; rail this file is about is TEMPLATE-minted — it has no `cqrt_alloc`, so 2b
; reported `0 violation(s)` on the leaking form too. The witness is the
; rolled-vs-hand-unrolled trace pair, and it is the only instrument in the tree
; that sees this class.
;
; ⚠ THE RAIL IS RETURNED TO |0> BEFORE IT IS FREED, AND THE ORDER IS THE WHOLE
; RULE-6 ARGUMENT: `cq_template_lshr_i32_hl_unc(%h_op, %h, %4)` re-runs the CNOTs
; (x^x=0) and THEN `cqrt_free(%h_op)` reclaims a proven-|0> rail. A free before the
; adjoint would be the hidden measurement that collapses `%h` (Rule 6), which is
; exactly what owner ruling D2 rejected when it read "discharge" as "free the
; entangled rail". The `CHECK-NEXT` below pins that order.
;
; ⚠ THE MEASURED RAIL IS **NOT** FREED, in either form: `%h_op1` (the `and`) is
; `cq_measure`'s, and `%h` is the user's register. Only the interior `%h_op` is
; discharged. The `LEAKCOUNT` prefix pins that there is exactly ONE free per
; function and it is the interior rail's.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @slice
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; the in-body per-trip pairing — forward, forward, ADJOINT, FREE, measure:
; CHECK: %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %{{[0-9]+}})
; CHECK-NEXT: %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1)
; CHECK-NEXT: call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
; CHECK-NEXT: %m{{[0-9]*}} = call i32 @cqrt_measure_i32(i32 %h_op1)
;
; ⚠ THE TRAILING LABEL IS LOAD-BEARING, NOT DECORATION — `-O1` inlines `@slice`
; into `@main`, so the module carries TWO copies of this stream and without a
; second `CHECK-LABEL` every positive above can be satisfied by the `@main` copy
; (bd `test_C_libtooling-1yeu`, the one-function-per-module gap seen from the
; inside: the second function is not a spare, it is a decoy).
; CHECK-LABEL: define i32 @main
;
; WHOLE-FILE COUNTS, in their OWN prefix — a positive `CHECK-COUNT` inside an
; ordered block WINDOWS every negative after it (Rule 12 fixture-hygiene defect
; (a)). Two functions, so: exactly one adjoint and one free per function, and
; never a free of the measured rail or of the user register.
; ⚠ COUNTS AND NEGATIVES IN SEPARATE PREFIXES — a positive `CHECK-COUNT` WINDOWS
; every negative after it, and the mutation matrix caught exactly that hole in this
; file's sibling `loop_leak_dephase_accept_pertrip_dead.ll` (Track T finding T-4).
; COUNT-COUNT-2: call void @cq_template_lshr_i32_hl_unc(
; COUNT-NOT: call void @cq_template_lshr_i32_hl_unc(
;
; NEG-NOT: call void @cqrt_free(i32 %h)
; NEG-NOT: call void @cqrt_free(i32 %h_op1)
; NEG-NOT: call void @cq_template_and_i32_hl_unc(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !19
    #dbg_value(i32 %1, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 1, !17, !DIExpression(), !21)
  br label %6, !dbg !22

2:                                                ; preds = %6
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !23
    #dbg_value(i32 %3, !15, !DIExpression(), !20)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !24
  %5 = add nsw i32 %4, %12, !dbg !25
  ret i32 %5, !dbg !26

6:                                                ; preds = %0, %6
  %7 = phi i32 [ 1, %0 ], [ %13, %6 ]
  %8 = phi i32 [ 0, %0 ], [ %12, %6 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !21)
    #dbg_value(i32 %8, !16, !DIExpression(), !20)
  %9 = lshr i32 %1, %7, !dbg !27
  %10 = and i32 %9, 1, !dbg !27
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !27
  %12 = add nsw i32 %11, %8, !dbg !29
    #dbg_value(i32 %12, !16, !DIExpression(), !20)
  %13 = add nuw nsw i32 %7, 1, !dbg !30
    #dbg_value(i32 %13, !17, !DIExpression(), !21)
  %14 = icmp eq i32 %13, 3, !dbg !31
  br i1 %14, label %2, label %6, !dbg !22, !llvm.loop !32
}

declare !dbg !36 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !41 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !44 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !45
    #dbg_value(i32 %1, !15, !DIExpression(), !47)
    #dbg_value(i32 0, !16, !DIExpression(), !47)
    #dbg_value(i32 1, !17, !DIExpression(), !48)
  br label %2, !dbg !49

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %9, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %8, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !48)
    #dbg_value(i32 %4, !16, !DIExpression(), !47)
  %5 = lshr i32 %1, %3, !dbg !50
  %6 = and i32 %5, 1, !dbg !50
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !50
  %8 = add nsw i32 %7, %4, !dbg !51
    #dbg_value(i32 %8, !16, !DIExpression(), !47)
  %9 = add nuw nsw i32 %3, 1, !dbg !52
    #dbg_value(i32 %9, !17, !DIExpression(), !48)
  %10 = icmp eq i32 %9, 3, !dbg !53
  br i1 %10, label %11, label %2, !dbg !49, !llvm.loop !54

11:                                               ; preds = %2
  %12 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !56
    #dbg_value(i32 %12, !15, !DIExpression(), !47)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !57
  %14 = add nsw i32 %13, %8, !dbg !58
  ret i32 %14, !dbg !59
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/s1_live_shift.c", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "b39f36c4cb86fe00e98355d03a3d54d7")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 7, type: !11, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 8, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 9, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 10, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 5)
!19 = !DILocation(line: 8, column: 13, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 10, column: 5, scope: !18)
!23 = !DILocation(line: 12, column: 9, scope: !10)
!24 = !DILocation(line: 13, column: 16, scope: !10)
!25 = !DILocation(line: 13, column: 14, scope: !10)
!26 = !DILocation(line: 13, column: 5, scope: !10)
!27 = !DILocation(line: 11, column: 14, scope: !28)
!28 = distinct !DILexicalBlock(scope: !18, file: !8, line: 10, column: 5)
!29 = !DILocation(line: 11, column: 11, scope: !28)
!30 = !DILocation(line: 10, column: 29, scope: !28)
!31 = !DILocation(line: 10, column: 23, scope: !28)
!32 = distinct !{!32, !22, !33, !34, !35}
!33 = !DILocation(line: 11, column: 14, scope: !18)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.unroll.disable"}
!36 = !DISubprogram(name: "cq_theta_si32", scope: !37, file: !37, line: 38, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!38 = !DISubroutineType(types: !39)
!39 = !{!13, !13, !40}
!40 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!41 = !DISubprogram(name: "cq_measure_si32", scope: !37, file: !37, line: 83, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DISubroutineType(types: !43)
!43 = !{!13, !13}
!44 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!45 = !DILocation(line: 8, column: 13, scope: !10, inlinedAt: !46)
!46 = distinct !DILocation(line: 15, column: 25, scope: !44)
!47 = !DILocation(line: 0, scope: !10, inlinedAt: !46)
!48 = !DILocation(line: 0, scope: !18, inlinedAt: !46)
!49 = !DILocation(line: 10, column: 5, scope: !18, inlinedAt: !46)
!50 = !DILocation(line: 11, column: 14, scope: !28, inlinedAt: !46)
!51 = !DILocation(line: 11, column: 11, scope: !28, inlinedAt: !46)
!52 = !DILocation(line: 10, column: 29, scope: !28, inlinedAt: !46)
!53 = !DILocation(line: 10, column: 23, scope: !28, inlinedAt: !46)
!54 = distinct !{!54, !49, !55, !34, !35}
!55 = !DILocation(line: 11, column: 14, scope: !18, inlinedAt: !46)
!56 = !DILocation(line: 12, column: 9, scope: !10, inlinedAt: !46)
!57 = !DILocation(line: 13, column: 16, scope: !10, inlinedAt: !46)
!58 = !DILocation(line: 13, column: 14, scope: !10, inlinedAt: !46)
!59 = !DILocation(line: 15, column: 18, scope: !44)
