; ⚠⚠⚠ 2026-09-15 — THE NAME IS HISTORY: THIS FILE IS NOW AN **ACCEPT**, AND ITS
; OWN L8 RETIREMENT TRIGGER (below, unedited) NAMED THE EVENT BY BEAD ID AND WAS
; CHARACTER-FOR-CHARACTER CORRECT:
;
;     "bd `tu9q` is the end state that turns this file into an ACCEPT whose
;      stream is the twin's 14 lines, rolled. Re-derive it then; do not delete it."
;
; bd `test_C_libtooling-tu9q` (the IN-LOOP `_unc` + `cqrt_free` PAIRING) landed in
; the loop-group merge of 2026-09-15 and the re-derivation is below.
;
; ⚠ FOUND AT THE MERGE, BY NEITHER TRACK AND BY NO REVIEW. Track S′ built this
; fixture on a binary WITHOUT the pairing; Track T built the pairing on a binary
; WITHOUT this fixture; the Rule-13 reviewer checked the three
; `control_phase_kickback_mixed_*_leak_control.ll` string-update fixtures against
; the Track-T binary and confirmed they still decline, but did NOT check this one
; or its sibling `loop_leak_dephase_reject_inloop_rotation.ll`. MEASURED at the
; merge gate, `ir-pass/test/*.ll` on four binaries: ORACLE `0e280fc6…` ACCEPT (the
; pre-S′ conjuncts), Track S′ `15f6a75a…` DECLINE, Track T `f972906e…` ACCEPT,
; merged ACCEPT. `CLAUDE.md` §4c, verbatim: **a composition is not cleared by
; clearing its parts** — here in the benign direction, which is exactly why a
; green-suite habit would have missed it.
;
; ⚠ IT IS NOT RENAMED, DELIBERATELY (bd `test_C_libtooling-gahu`, `CLAUDE.md` L8):
; a `git mv`'d fixture can be RESURRECTED by a merge, leaving one module under two
; names with contradictory verdicts, invisible to every review that ran before the
; merge. Renaming is owed as its own change.
;
; THE RE-DERIVATION, and it is the trigger's own end state. The loop is now MARKED
; (the bd `tu9q` root-mint escape admits `y`'s root mint, so `markIfRailLocal`
; marks the body), the compare rail gets its adjoint and its free IN THE BODY once
; per trip, and `declineDephasingUnmarkedLoopRails` exits at conjunct (1) on the
; loop's OWN marking — which is what conjunct (1) always meant, and which bd
; `test_C_libtooling-emkg` had to fix conjunct (1) to make true (it used to be
; satisfiable by a marking on a strictly-deeper SUBLOOP's blocks; this loop has no
; subloop, so that fix does not move this file).
;
; MEASURED on the merged binary `9dd81edb9f949bb5` against the hand-unrolled twin
; (`loopfix/probes/c1_cmp_rail_data{,_un}.c`): ROLLED **14 trace lines, BYTE-
; IDENTICAL** to the twin's 14 (`diff` empty) — where the ORACLE emitted 10 and
; the twin 14. The divergence this file was built to refuse is CLOSED, not hidden.
;
; ⚠ 2b IS NOT THE WITNESS AND NEVER WAS: it counts `cqrt_alloc` SITES and these
; rails are TEMPLATE-minted, so it reported `0 violation(s)` on the leaking form
; too. The rolled-vs-hand-unrolled trace pair is the only instrument in the tree
; that sees this class.
;
; ⚠ NEW L8 RETIREMENT TRIGGER: if this file ever goes red with
; `rolled body leaks a rail entangled with a rotated register`, the pairing has
; stopped marking this loop — re-derive from `c1_cmp_rail_data.c` and its twin
; BEFORE touching the fence; a red here is a capability regression, not a fence
; that grew.
;
; ── THE HISTORICAL HEADER FOLLOWS, UNEDITED. Read it as the record of WHY the
; ── decline existed; its verdict line is superseded by the banner above.
;
; loop_leak_dephase_reject_cmp_rail_data.ll — DECLINE (bd
; `test_C_libtooling-7845`, P1, closed 2026-09-15). A TAINTED COMPARE USED AS
; **DATA** IS AN ORDINARY OUT-OF-PLACE RAIL, AND CONJUNCT (3) USED TO SCAN
; `BinaryOperator` ONLY.
;
;     int y = 5; cq_theta(&y, 0.5);
;     int s = 0;
;     for (int k = 1; k <= 2; ++k) s += cq_measure(y > k);
;     cq_theta(&y, 0.9);                 // the interference
;     return s + cq_measure(y);
;
; Five lines of C, NO TAINTED CONTROL FLOW ANYWHERE, and the body holds NO
; `BinaryOperator` at all — its only rail-minting interior op is the `icmp`
; (`icmp -> zext -> cq_measure`). EVERY OTHER CONJUNCT WAS SATISFIED, so this was
; a SINGLE-CONJUNCT miss.
;
; ⚠ THE RETIRED RATIONALE, QUOTED BECAUSE THE FIX IS NOT THE OBVIOUS ONE. The old
; comment justified the opcode restriction with "a compare rail IS the region's
; own flag, which `emitCondNetwork` strips and frees itself". That is true of a
; compare that IS a region flag and FALSE of one used as DATA: `CompareLowering`
; mints an ordinary out-of-place `cq_template_icmp_<pred>_<W>_hl` rail — a
; which-path copy — with no region and no `emitCondNetwork` anywhere in the
; module. `CLAUDE.md` L4: a set-membership question answered by an OPCODE-CLASS
; PROXY loses. The fix is therefore NOT `isa<BinaryOperator> || isa<CmpInst>`; it
; asks the owners of the membership question — `isDataPositionCompare` (is this
; compare a FLAG Phase 4 owns, or data?) and `compareFlagMintable` (does a
; template exist for it?) — by CALLING them (Rule 14).
;
; MEASURED, ORACLE `cq-opt` 0e280fc62a91cec2… (the pre-fix binary): `opt` exit 0,
; verify-clean, rolled 10 trace lines against the hand-unrolled twin's 14. The
; rolled form emits `cq_template_icmp_sgt_i32_hl(h0,1) -> h1` and
; `…(h0,2) -> h3`, NEITHER ever `_unc`-ed and neither ever freed; the twin emits
; both adjoints and both `cqrt_free`. Then the TENSORED `cqrt_ry_i32(h0, 0.9)`
; lands on the register both rails copy and `cqrt_measure_i32(h0)` is the
; observable — `CLAUDE.md` Rule 8. The `zext` rail is MEASURE-OWNED and left
; allocated by both forms (`railIsInterior` excludes it); the divergence is
; exactly the two compare rails.
;
; ⚠ RULE 17 / L8 RETIREMENT TRIGGER: identical to the sibling reject fixtures —
; the refused program receives an INVALID circuit today, and bd `tu9q` is the end
; state that turns this file into an ACCEPT whose stream is the twin's 14 lines,
; rolled. Re-derive it then; do not delete it.
;
; ⚠ STRICT stage 2b reported `2 rail mint(s) of which 2 left allocated, 0
; cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven` on the accepting
; pre-fix module. Recorded as evidence of its BLINDNESS to template-minted rails,
; never as clearance.
;
; ⚠ FIXTURE HYGIENE (b): a `DS_Error` decline writes 0 BYTES to stdout, so an
; IR-text `CHECK-NOT` here would be VACUOUS. The property is pinned by the `not`
; inversion on the RUN line, and this file was validated by BINARY MUTATION (it
; does not match on the pre-fix oracle, where `opt` exits 0).
;
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UNCCOUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FREECOUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; THE ORDERED STREAM — mint, cast, ADJOINT, FREE, measure. The order is the whole
; Rule-6 argument: `…_unc` re-runs the CNOTs (x^x=0) and THEN `cqrt_free` reclaims
; a proven-|0> rail. A free before the adjoint would be the hidden measurement
; that collapses `%h`.
; CHECK-LABEL: define i32 @slice
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; CHECK: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %{{[0-9]+}})
; CHECK-NEXT: %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
; CHECK-NEXT: %m{{[0-9]*}} = call i32 @cqrt_measure_i32(i32 %h_cast)
;
; ⚠ THE TRAILING LABEL IS LOAD-BEARING: `-O1` inlines `@slice` into `@main`, so
; the module carries TWO copies of this stream and without a second `CHECK-LABEL`
; every positive above can be satisfied by the `@main` copy (bd
; `test_C_libtooling-1yeu` — the second function is a DECOY, not a spare).
; CHECK-LABEL: define i32 @main
;
; WHOLE-FILE COUNTS, ONE COUNTED SYMBOL PER PREFIX, NEGATIVES SOMEWHERE ELSE
; ENTIRELY (Rule 12 fixture-hygiene defect (a): a positive `CHECK-COUNT` above a
; negative WINDOWS it). Two functions, one pair each.
; UNCCOUNT-COUNT-2: call void @cq_template_icmp_sgt_i32_hl_unc(
; UNCCOUNT-NOT: call void @cq_template_icmp_sgt_i32_hl_unc(
;
; FREECOUNT-COUNT-2: call void @cqrt_free(
; FREECOUNT-NOT: call void @cqrt_free(
;
; PURE NEGATIVES — never a free of the user's register, never a free of the
; measure-owned `zext` rail, never an adjoint of it, and no decline text.
; NEG-NOT: call void @cqrt_free(i32 %h)
; NEG-NOT: call void @cqrt_free(i32 %h_cast)
; NEG-NOT: call void @cq_template_zext_i1_to_i32_unc(
; NEG-NOT: rolled body leaks a rail

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
  %9 = icmp sgt i32 %1, %7, !dbg !27
  %10 = zext i1 %9 to i32, !dbg !27
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
  %5 = icmp sgt i32 %1, %3, !dbg !50
  %6 = zext i1 %5 to i32, !dbg !50
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
!8 = !DIFile(filename: "b11_cmp_rail_data.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "b2245a2500742b339863c7f57ad13b1b")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 9, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!19 = !DILocation(line: 7, column: 13, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 9, column: 5, scope: !18)
!23 = !DILocation(line: 11, column: 9, scope: !10)
!24 = !DILocation(line: 12, column: 16, scope: !10)
!25 = !DILocation(line: 12, column: 14, scope: !10)
!26 = !DILocation(line: 12, column: 5, scope: !10)
!27 = !DILocation(line: 10, column: 14, scope: !28)
!28 = distinct !DILexicalBlock(scope: !18, file: !8, line: 9, column: 5)
!29 = !DILocation(line: 10, column: 11, scope: !28)
!30 = !DILocation(line: 9, column: 29, scope: !28)
!31 = !DILocation(line: 9, column: 23, scope: !28)
!32 = distinct !{!32, !22, !33, !34, !35}
!33 = !DILocation(line: 10, column: 14, scope: !18)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.unroll.disable"}
!36 = !DISubprogram(name: "cq_theta_si32", scope: !37, file: !37, line: 38, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_S", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!38 = !DISubroutineType(types: !39)
!39 = !{!13, !13, !40}
!40 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!41 = !DISubprogram(name: "cq_measure_si32", scope: !37, file: !37, line: 83, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DISubroutineType(types: !43)
!43 = !{!13, !13}
!44 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 14, type: !11, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!45 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !46)
!46 = distinct !DILocation(line: 14, column: 25, scope: !44)
!47 = !DILocation(line: 0, scope: !10, inlinedAt: !46)
!48 = !DILocation(line: 0, scope: !18, inlinedAt: !46)
!49 = !DILocation(line: 9, column: 5, scope: !18, inlinedAt: !46)
!50 = !DILocation(line: 10, column: 14, scope: !28, inlinedAt: !46)
!51 = !DILocation(line: 10, column: 11, scope: !28, inlinedAt: !46)
!52 = !DILocation(line: 9, column: 29, scope: !28, inlinedAt: !46)
!53 = !DILocation(line: 9, column: 23, scope: !28, inlinedAt: !46)
!54 = distinct !{!54, !49, !55, !34, !35}
!55 = !DILocation(line: 10, column: 14, scope: !18, inlinedAt: !46)
!56 = !DILocation(line: 11, column: 9, scope: !10, inlinedAt: !46)
!57 = !DILocation(line: 12, column: 16, scope: !10, inlinedAt: !46)
!58 = !DILocation(line: 12, column: 14, scope: !10, inlinedAt: !46)
!59 = !DILocation(line: 14, column: 18, scope: !44)
