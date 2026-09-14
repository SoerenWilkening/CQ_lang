; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/fix_r1_probes/u1.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/fix_r1_probes/u1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !15, !DIExpression(), !19)
    #dbg_value(i8 0, !16, !DIExpression(), !19)
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !20
    #dbg_value(i1 %1, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !19)
    #dbg_value(i1 %1, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !19)
    #dbg_value(i1 %1, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !19)
  %2 = select i1 %1, i32 2, i32 5, !dbg !23
    #dbg_value(i32 %2, !15, !DIExpression(), !19)
  %3 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !24
  %4 = zext i1 %3 to i32, !dbg !24
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext undef) #2, !dbg !25
  %6 = zext i1 %5 to i32, !dbg !25
  %7 = add nuw nsw i32 %6, %4, !dbg !26
  %8 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !27
  %9 = add nsw i32 %7, %8, !dbg !28
  ret i32 %9, !dbg !29
}

declare !dbg !30 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !35 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !38 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/fix_r1_probes/u1.c", directory: "/Users/sorenwilkening/Desktop/CQ_undef", checksumkind: CSK_MD5, checksum: "ea33cd5042e4743df5775cab888fb8af")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 5, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "b2", scope: !10, file: !8, line: 6, type: !17)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 7, column: 23, scope: !21)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 7, column: 16)
!22 = distinct !DILexicalBlock(scope: !10, file: !8, line: 7, column: 9)
!23 = !DILocation(line: 8, column: 9, scope: !10)
!24 = !DILocation(line: 9, column: 12, scope: !10)
!25 = !DILocation(line: 9, column: 29, scope: !10)
!26 = !DILocation(line: 9, column: 27, scope: !10)
!27 = !DILocation(line: 9, column: 46, scope: !10)
!28 = !DILocation(line: 9, column: 44, scope: !10)
!29 = !DILocation(line: 9, column: 5, scope: !10)
!30 = !DISubprogram(name: "cq_theta_i1", scope: !31, file: !31, line: 32, type: !32, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!31 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_undef", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!32 = !DISubroutineType(types: !33)
!33 = !{!17, !17, !34}
!34 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!35 = !DISubprogram(name: "cq_measure_i1", scope: !31, file: !31, line: 77, type: !36, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!36 = !DISubroutineType(types: !37)
!37 = !{!17, !17}
!38 = !DISubprogram(name: "cq_measure_si32", scope: !31, file: !31, line: 83, type: !39, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!39 = !DISubroutineType(types: !40)
!40 = !{!13, !13}
