; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r17_select_unclaimed_phi.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r17_select_unclaimed_phi.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !21
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i32 0, !18, !DIExpression(), !22)
    #dbg_value(i32 0, !19, !DIExpression(), !23)
    #dbg_value(i32 poison, !19, !DIExpression(), !23)
    #dbg_value(i1 poison, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i32 poison, !18, !DIExpression(), !22)
  %2 = xor i1 %1, true, !dbg !24
  %3 = select i1 %1, i32 2, i32 5
  %4 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #2, !dbg !25
  %5 = zext i1 %4 to i32, !dbg !25
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !26
  %7 = add nsw i32 %6, %5, !dbg !27
  ret i32 %7, !dbg !28
}

declare !dbg !29 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !34 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !37 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r17_select_unclaimed_phi.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "ce03c9f45bef5cae0052739f01a96f8e")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !13, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19}
!17 = !DILocalVariable(name: "b", scope: !12, file: !8, line: 5, type: !10)
!18 = !DILocalVariable(name: "a", scope: !12, file: !8, line: 6, type: !15)
!19 = !DILocalVariable(name: "i", scope: !20, file: !8, line: 7, type: !15)
!20 = distinct !DILexicalBlock(scope: !12, file: !8, line: 7, column: 5)
!21 = !DILocation(line: 5, column: 14, scope: !12)
!22 = !DILocation(line: 0, scope: !12)
!23 = !DILocation(line: 0, scope: !20)
!24 = !DILocation(line: 7, column: 5, scope: !20)
!25 = !DILocation(line: 11, column: 12, scope: !12)
!26 = !DILocation(line: 11, column: 28, scope: !12)
!27 = !DILocation(line: 11, column: 26, scope: !12)
!28 = !DILocation(line: 11, column: 5, scope: !12)
!29 = !DISubprogram(name: "cq_theta_i1", scope: !30, file: !30, line: 32, type: !31, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!30 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!31 = !DISubroutineType(types: !32)
!32 = !{!10, !10, !33}
!33 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!34 = !DISubprogram(name: "cq_measure_i1", scope: !30, file: !30, line: 77, type: !35, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!35 = !DISubroutineType(types: !36)
!36 = !{!10, !10}
!37 = !DISubprogram(name: "cq_measure_si32", scope: !30, file: !30, line: 83, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = !DISubroutineType(types: !39)
!39 = !{!15, !15}
