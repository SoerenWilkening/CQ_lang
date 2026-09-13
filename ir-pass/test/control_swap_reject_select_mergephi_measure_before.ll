
; control_swap_reject_select_mergephi_measure_before.ll — DECLINE, and THE ONE
; RED-GREEN PIN of Track M's ladder (bd `boi6` D-B, hazard H-2; probe `m05`).
;
; ⚠ RED ON THE ORACLE FOR THE WRONG REASON, GREEN ON THE SUBJECT FOR THE RIGHT
; ONE. On the frozen ORACLE (`e96f89c`) this module declines `control flow` —
; the LEAF GRAMMAR pre-empts the ladder, so the measurement is never even asked
; about. With the φ admitted as a leaf the ladder runs, and rung (ii) must be the
; gate that owns it. The string MOVES; the disposition does not.
;
; THE HAZARD IT PINS, AND IT IS AN OVER-ACCEPT ONE CONSTRUCT WIDE. `-O1` gives
; the user's `cq_measure(b1)` the MERGE φ as its argument (`%7 = call
; @cq_measure_i1(i1 %6)` below), while `railWireNamesBackward` `break`s at the
; first non-call — so a rung-(ii) closure seeded from the hoisted arm theta alone
; is the SINGLETON `{T}` and this measurement is INVISIBLE. The lowering would
; then mint the select's `cqrt_cnot` control read off a register the user had
; already COLLAPSED. Rung (ii) is therefore asked over `condProvenance(P)` —
; `{φ, T}` — which is EXACTLY the seed set rung (iii)/gate 2c walks: ONE closure,
; TWO rungs (the 8h7d.5 F-1/F-3 lesson, CLAUDE.md L2).
;
; This module is `clang -O1 -g` output verbatim (probe `m05.c`:
; `if (a >= 3) b1 = cq_theta(b1, .5); int mb = cq_measure(b1); if (b1) a -= 3;`),
; debug metadata included, so the fused two-phi diamond and the measure's
; placement are `-O1`'s and not a fixture author's.

; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m05.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !16, !DIExpression(), !21)
    #dbg_value(i8 0, !17, !DIExpression(), !21)
    #dbg_value(i8 0, !19, !DIExpression(), !21)
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
    #dbg_value(i32 poison, !16, !DIExpression(), !21)
  br i1 %1, label %4, label %2, !dbg !25

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !26
    #dbg_value(i1 %3, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
  br label %4, !dbg !29

4:                                                ; preds = %2, %0
  %5 = phi i32 [ 5, %2 ], [ 2, %0 ], !dbg !21
  %6 = phi i1 [ %3, %2 ], [ false, %0 ], !dbg !21
    #dbg_value(i32 %5, !16, !DIExpression(), !21)
    #dbg_value(i8 poison, !19, !DIExpression(), !21)
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !30
    #dbg_value(i1 %7, !20, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_stack_value), !21)
  %8 = add nsw i32 %5, -3
  %9 = select i1 %6, i32 %8, i32 %5, !dbg !31
  %10 = zext i1 %7 to i32, !dbg !30
    #dbg_value(i32 %10, !20, !DIExpression(), !21)
    #dbg_value(i32 %9, !16, !DIExpression(), !21)
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !32
  %12 = zext i1 %11 to i32, !dbg !32
  %13 = add nuw nsw i32 %12, %10, !dbg !33
  %14 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !34
  %15 = add nsw i32 %13, %14, !dbg !35
  ret i32 %15, !dbg !36
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m05.c", directory: "/Users/sorenwilkening/Desktop/CQ_mphi", checksumkind: CSK_MD5, checksum: "0214d66205270c409fac50d1284eea57")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 3, type: !12, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackM/probes/m05.c", directory: "", checksumkind: CSK_MD5, checksum: "0214d66205270c409fac50d1284eea57")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !19, !20}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 4, type: !14)
!17 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 5, type: !18)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 6, type: !18)
!20 = !DILocalVariable(name: "mb", scope: !10, file: !11, line: 10, type: !14)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 7, column: 23, scope: !23)
!23 = distinct !DILexicalBlock(scope: !24, file: !11, line: 7, column: 16)
!24 = distinct !DILexicalBlock(scope: !10, file: !11, line: 7, column: 9)
!25 = !DILocation(line: 9, column: 9, scope: !10)
!26 = !DILocation(line: 9, column: 23, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !11, line: 9, column: 16)
!28 = distinct !DILexicalBlock(scope: !10, file: !11, line: 9, column: 9)
!29 = !DILocation(line: 9, column: 42, scope: !27)
!30 = !DILocation(line: 10, column: 14, scope: !10)
!31 = !DILocation(line: 11, column: 9, scope: !10)
!32 = !DILocation(line: 12, column: 12, scope: !10)
!33 = !DILocation(line: 12, column: 27, scope: !10)
!34 = !DILocation(line: 12, column: 34, scope: !10)
!35 = !DILocation(line: 12, column: 32, scope: !10)
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

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
