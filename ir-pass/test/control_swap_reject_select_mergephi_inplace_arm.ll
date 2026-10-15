; control_swap_reject_select_mergephi_inplace_arm.ll — DECLINE, and it is an
; ACKNOWLEDGED OVER-DECLINE that is deliberately NOT fixed. bd `boi6` D-B /
; Track M, round-1 finding **F-M3**; probe `r01_inplace_arm_bool.c`.
;
; ⚠ RED ON THE ORACLE FOR A DIFFERENT REASON. The ORACLE declines `control flow`
; (the leaf grammar refuses the φ, so nothing is examined). Here the grammar
; admits it, rung 0 PASSES — the region IS a claimed `InPlaceRotation` — and
; rung (iii)/gate 2c owns it with `condition predates a non-diagonal gate`. The
; string moves; the disposition does not.
;
; THE SHAPE: an in-place Ry **ARM** rather than a state PREP. `cq_theta(&r,.7)`
; makes `r` a live rail; `if (b0 == 1) { cq_theta(&r, .3); }` rotates it IN
; PLACE under control, so the merge φ is `[theta(r_old), r_old]` — two basis
; labels of ONE register, both on one wire.
;
; ⚠ THE CIRCUIT IS VALID AND THE COMPILER REFUSES IT ANYWAY. Stated plainly
; because an over-decline of a valid circuit is a DEFECT, not a safety margin
; (owner ruling 2026-09-11): there is ONE physical rail for `r`;
; `lowerRotations` RAUWs `%r_old` and the arm theta to the SAME `i32` handle
; (chained); M-β RAUWs the φ to the arm theta; and `SelectMergeEmit` inserts its
; whole stream immediately BEFORE the select, i.e. AFTER the hoisted controlled
; Ry. So the CNOT copy would read exactly the basis the source's `r` denotes at
; that point. The decline comes from the SEED SET, not from the physics:
; `condProvenance(φ)` walks the φ's operand edges and so drags the PRE-rotation
; name into `RailProv`, on whose wire the arm's own theta sits; the DT prong only
; accepts a gate provably AFTER the select and this one is provably BEFORE, so no
; accepting reading exists.
;
; ⚠⚠ RETIREMENT TRIGGER — AND THE ORDER OF OPERATIONS IS THE WHOLE POINT.
; DO NOT "fix" this by narrowing the φ's rung-(iii) seed to the arm theta alone.
; That same cone is currently the ONLY thing that refuses an in-place-ARM φ whose
; PRE-rotation name has SIBLING READERS — i.e. bd **`3d8q`** in its in-place-arm
; form (two SSA names, one rail, a `cq_theta`/`cq_measure` reader of the stale
; name, which the pass-wide stale-record guard never asks about because it sweeps
; PURE ops only). Narrowing the seed first would convert this over-decline into an
; OVER-ACCEPT of that class. The correct sequence is: land the `3d8q` fence, THEN
; re-derive this seed, THEN flip this fixture and derive its stream from the pass
; output. Do not delete it.
;
; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; FOLLOW-UP: bd test_C_libtooling-dm7f.60 — the 4.4 select consumer still refuses an in-place-arm merge phi that the kickback and Ry consumers admit since dm7f.53 (`condTreeCoveredPhiGates`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/review_M_r1_probes/r01_inplace_arm_bool.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/review_M_r1_probes/r01_inplace_arm_bool.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !21
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FE6666666666666) #2, !dbg !24
  br i1 %1, label %3, label %5, !dbg !25

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 3.000000e-01) #2, !dbg !26
  br label %5, !dbg !29

5:                                                ; preds = %3, %0
  %6 = phi i32 [ 2, %3 ], [ 5, %0 ]
  %7 = phi i1 [ %4, %3 ], [ %2, %0 ]
  %8 = add nsw i32 %6, -3
  %9 = select i1 %7, i32 %8, i32 %6, !dbg !30
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !31
  %11 = zext i1 %10 to i32, !dbg !31
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #2, !dbg !32
  %13 = zext i1 %12 to i32, !dbg !32
  %14 = add nuw nsw i32 %13, %11, !dbg !33
  %15 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !34
  %16 = add nsw i32 %14, %15, !dbg !35
  ret i32 %16, !dbg !36
}

declare !dbg !37 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !42 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !45 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/review_M_r1_probes/r01_inplace_arm_bool.c", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "8db098e6e12003d3dd86328f13054633")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 5, type: !12, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/review_M_r1_probes/r01_inplace_arm_bool.c", directory: "", checksumkind: CSK_MD5, checksum: "8db098e6e12003d3dd86328f13054633")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !19}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 6, type: !14)
!17 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 6, type: !18)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !DILocalVariable(name: "r", scope: !10, file: !11, line: 6, type: !18)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 7, column: 24, scope: !22)
!22 = distinct !DILexicalBlock(scope: !23, file: !11, line: 7, column: 17)
!23 = distinct !DILexicalBlock(scope: !10, file: !11, line: 7, column: 9)
!24 = !DILocation(line: 9, column: 9, scope: !10)
!25 = !DILocation(line: 10, column: 9, scope: !10)
!26 = !DILocation(line: 10, column: 24, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !11, line: 10, column: 18)
!28 = distinct !DILexicalBlock(scope: !10, file: !11, line: 10, column: 9)
!29 = !DILocation(line: 10, column: 42, scope: !27)
!30 = !DILocation(line: 11, column: 9, scope: !10)
!31 = !DILocation(line: 12, column: 12, scope: !10)
!32 = !DILocation(line: 12, column: 29, scope: !10)
!33 = !DILocation(line: 12, column: 27, scope: !10)
!34 = !DILocation(line: 12, column: 45, scope: !10)
!35 = !DILocation(line: 12, column: 43, scope: !10)
!36 = !DILocation(line: 12, column: 5, scope: !10)
!37 = !DISubprogram(name: "cq_theta_i1", scope: !38, file: !38, line: 32, type: !39, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!39 = !DISubroutineType(types: !40)
!40 = !{!18, !18, !41}
!41 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!42 = !DISubprogram(name: "cq_measure_i1", scope: !38, file: !38, line: 77, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DISubroutineType(types: !44)
!44 = !{!18, !18}
!45 = !DISubprogram(name: "cq_measure_si32", scope: !38, file: !38, line: 83, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DISubroutineType(types: !47)
!47 = !{!14, !14}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
