; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/fix_r1_probes/u2.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/fix_r1_probes/u2.c"
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
    #dbg_value(i32 poison, !15, !DIExpression(), !19)
  br i1 %1, label %4, label %2, !dbg !23

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext undef, double noundef 5.000000e-01) #2, !dbg !24
    #dbg_value(i1 %3, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !19)
  br label %4, !dbg !27

4:                                                ; preds = %2, %0
  %5 = phi i32 [ 5, %2 ], [ 2, %0 ]
  %6 = phi i1 [ %3, %2 ], [ undef, %0 ]
    #dbg_value(i32 %5, !15, !DIExpression(), !19)
    #dbg_value(i8 poison, !18, !DIExpression(), !19)
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !28
  %8 = zext i1 %7 to i32, !dbg !28
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !29
  %10 = zext i1 %9 to i32, !dbg !29
  %11 = add nuw nsw i32 %10, %8, !dbg !30
  %12 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !31
  %13 = add nsw i32 %11, %12, !dbg !32
  ret i32 %13, !dbg !33
}

declare !dbg !34 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !39 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !42 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/fix_r1_probes/u2.c", directory: "/Users/sorenwilkening/Desktop/CQ_undef", checksumkind: CSK_MD5, checksum: "a528e1ba9ff933a06144d537c88ca52c")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 5, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "b1", scope: !10, file: !8, line: 6, type: !17)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 7, column: 23, scope: !21)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 7, column: 16)
!22 = distinct !DILexicalBlock(scope: !10, file: !8, line: 7, column: 9)
!23 = !DILocation(line: 9, column: 9, scope: !10)
!24 = !DILocation(line: 9, column: 23, scope: !25)
!25 = distinct !DILexicalBlock(scope: !26, file: !8, line: 9, column: 16)
!26 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 9)
!27 = !DILocation(line: 9, column: 42, scope: !25)
!28 = !DILocation(line: 10, column: 12, scope: !10)
!29 = !DILocation(line: 10, column: 29, scope: !10)
!30 = !DILocation(line: 10, column: 27, scope: !10)
!31 = !DILocation(line: 10, column: 46, scope: !10)
!32 = !DILocation(line: 10, column: 44, scope: !10)
!33 = !DILocation(line: 10, column: 5, scope: !10)
!34 = !DISubprogram(name: "cq_theta_i1", scope: !35, file: !35, line: 32, type: !36, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!35 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_undef", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!36 = !DISubroutineType(types: !37)
!37 = !{!17, !17, !38}
!38 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!39 = !DISubprogram(name: "cq_measure_i1", scope: !35, file: !35, line: 77, type: !40, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!40 = !DISubroutineType(types: !41)
!41 = !{!17, !17}
!42 = !DISubprogram(name: "cq_measure_si32", scope: !35, file: !35, line: 83, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DISubroutineType(types: !44)
!44 = !{!13, !13}
