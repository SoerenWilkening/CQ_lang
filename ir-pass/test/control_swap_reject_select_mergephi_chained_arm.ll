; control_swap_reject_select_mergephi_chained_arm.ll — DECLINE, and it is the
; RED-GREEN PIN that the phi admission does NOT bypass the wire fence. bd `boi6`
; D-B / Track M; this module is probe `p20`, the probe the increment is NAMED
; after, as `clang -O1 -g` hands it over.
;
; ⚠ RED ON THE ORACLE FOR THE WRONG REASON, GREEN HERE FOR THE RIGHT ONE. On the
; frozen ORACLE (`e96f89c`) this declines `control flow` — the LEAF GRAMMAR
; refuses the phi, so the wire is never examined. With the phi admitted the ladder
; runs, rung 0 PASSES (the diamond IS claimed as an in-place rotation), and
; rung (iii)/gate 2c is what must own it. The string MOVES to
; `condition predates a non-diagonal gate`; the disposition does not.
;
; WHY THIS ONE IS GENUINELY DIRTY, AND IT IS THE WHOLE DISTINCTION TRACK M RESTS
; ON. The arm theta here is CHAINED: `%5 = cq_theta_i1(i1 %2, double 0.9)` takes
; the SEED `%2` as its arg-0, so it is an IN-PLACE, NON-DIAGONAL Ry sitting on the
; condition's own wire, and the merge phi `%7` names two DIFFERENT basis labels of
; ONE register. `findNonDiagonalWireGate` answers DIRTY off-ancestry and the DT
; prong cannot rescue it (the gate is not after the select — it is before).
;
; THE OWNER'S FILE IS THE OPPOSITE CASE and that is why it lowers: its arm theta
; is a SOURCE (`cq_theta_i1(i1 false, .5)`, a CLASSICAL arg-0) and the phi's other
; incoming is the constant seed, so `walkNonDiagonalWireGates`' backward closure
; stops at the classical arg-0 and marks the producing theta ON-ANCESTRY EXEMPT —
; the wire is CLEAN. Read this file and
; `control_swap_accept_select_mergephi_rail_negated.ll` as a PAIR: same construct,
; opposite verdicts, and the discriminator is what the arm theta's arg-0 is.
;
; ⚠ IT ALSO CORRECTS `SCOPE_boi6.md` §0.3. That record said admitting the phi
; "would buy `p5` nothing" because the wire fence is the second blocker — TRUE of
; `p5`/`p20`, which is this file, and FALSE of the owner's file, whose `int` twins
; `m11`/`m12`/`m26` already accept on the ORACLE with COMPAREs over the same phi.
; The wire half of `p20` stays bd `drbq.7`'s.
;
; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-boi6/probes/p20.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-boi6/probes/p20.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483646, -2147483648) i32 @main() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 2.000000e-01) #2, !dbg !21
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #2, !dbg !23
  %3 = icmp sgt i32 %1, 3, !dbg !24
  br i1 %3, label %4, label %6, !dbg !26

4:                                                ; preds = %0
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 9.000000e-01) #2, !dbg !27
  br label %6, !dbg !28

6:                                                ; preds = %4, %0
  %7 = phi i1 [ %5, %4 ], [ %2, %0 ]
  %8 = select i1 %7, i32 2, i32 5, !dbg !29
  %9 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !30
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #2, !dbg !31
  %11 = zext i1 %10 to i32, !dbg !31
  %12 = add i32 %8, %9, !dbg !32
  %13 = add i32 %12, %11, !dbg !33
  ret i32 %13, !dbg !34
}

declare !dbg !35 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !40 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !43 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare !dbg !46 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!11}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-boi6/probes/p20.c", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "b6cd834cd576d6b738982a3207ce988e")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-boi6/probes/p20.c", directory: "", checksumkind: CSK_MD5, checksum: "b6cd834cd576d6b738982a3207ce988e")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20}
!18 = !DILocalVariable(name: "q", scope: !12, file: !13, line: 4, type: !16)
!19 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 5, type: !10)
!20 = !DILocalVariable(name: "a", scope: !12, file: !13, line: 7, type: !16)
!21 = !DILocation(line: 4, column: 14, scope: !12)
!22 = !DILocation(line: 0, scope: !12)
!23 = !DILocation(line: 5, column: 14, scope: !12)
!24 = !DILocation(line: 6, column: 11, scope: !25)
!25 = distinct !DILexicalBlock(scope: !12, file: !13, line: 6, column: 9)
!26 = !DILocation(line: 6, column: 9, scope: !12)
!27 = !DILocation(line: 6, column: 20, scope: !25)
!28 = !DILocation(line: 6, column: 16, scope: !25)
!29 = !DILocation(line: 7, column: 13, scope: !12)
!30 = !DILocation(line: 8, column: 12, scope: !12)
!31 = !DILocation(line: 8, column: 28, scope: !12)
!32 = !DILocation(line: 8, column: 26, scope: !12)
!33 = !DILocation(line: 8, column: 42, scope: !12)
!34 = !DILocation(line: 8, column: 5, scope: !12)
!35 = !DISubprogram(name: "cq_theta_si32", scope: !36, file: !36, line: 38, type: !37, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!36 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!37 = !DISubroutineType(types: !38)
!38 = !{!16, !16, !39}
!39 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!40 = !DISubprogram(name: "cq_theta_i1", scope: !36, file: !36, line: 32, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DISubroutineType(types: !42)
!42 = !{!10, !10, !39}
!43 = !DISubprogram(name: "cq_measure_si32", scope: !36, file: !36, line: 83, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DISubroutineType(types: !45)
!45 = !{!16, !16}
!46 = !DISubprogram(name: "cq_measure_i1", scope: !36, file: !36, line: 77, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DISubroutineType(types: !48)
!48 = !{!10, !10}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
