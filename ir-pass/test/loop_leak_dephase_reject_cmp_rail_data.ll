; loop_leak_dephase_reject_cmp_rail_data.ll — DECLINE (bd
; `test_C_libtooling-7845`, P1, closed 2026-09-15). A TAINTED COMPARE USED AS
; **DATA** IS AN ORDINARY OUT-OF-PLACE RAIL, AND CONJUNCT (3) USED TO SCAN
; `BinaryOperator` ONLY.
;
;     int y = cq_theta(5, 0.5);
;     int s = 0;
;     for (int k = 1; k <= 2; ++k) s += cq_measure(y > k);
;     y = cq_theta(y, 0.9);                 // the interference
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq loop lowering: rolled body leaks a rail entangled with a rotated register
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
