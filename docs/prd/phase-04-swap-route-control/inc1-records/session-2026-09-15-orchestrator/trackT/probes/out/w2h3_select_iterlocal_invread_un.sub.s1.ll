; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2h3_select_iterlocal_invread_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2h3_select_iterlocal_invread_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !27
    #dbg_value(i32 %1, !17, !DIExpression(), !28)
    #dbg_value(i32 0, !18, !DIExpression(), !28)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !29
    #dbg_value(i32 %2, !19, !DIExpression(), !30)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !31
    #dbg_value(i1 %3, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !30)
  %4 = select i1 %3, i32 2, i32 5, !dbg !32
    #dbg_value(i32 %4, !22, !DIExpression(), !30)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2, !dbg !33
  %6 = lshr i32 %2, 1, !dbg !34
  %7 = and i32 %6, 1, !dbg !34
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !34
  %9 = and i32 %1, 1, !dbg !35
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !35
    #dbg_value(i32 poison, !18, !DIExpression(), !28)
  %11 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !36
    #dbg_value(i32 %11, !23, !DIExpression(), !37)
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !38
    #dbg_value(i1 %12, !25, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !37)
  %13 = select i1 %12, i32 2, i32 5, !dbg !39
    #dbg_value(i32 %13, !26, !DIExpression(), !37)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !40
  %15 = lshr i32 %11, 1, !dbg !41
  %16 = and i32 %15, 1, !dbg !41
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #2, !dbg !41
  %18 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !42
    #dbg_value(i32 %24, !18, !DIExpression(), !28)
  %19 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !43
  %20 = add i32 %8, %5, !dbg !44
  %21 = add i32 %20, %10, !dbg !45
  %22 = add i32 %21, %14, !dbg !46
  %23 = add i32 %22, %17, !dbg !47
  %24 = add i32 %23, %18, !dbg !48
  %25 = add nsw i32 %24, %19, !dbg !49
  ret i32 %25, !dbg !50
}

declare !dbg !51 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !56 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !59 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !62 {
  %1 = tail call i32 @slice(), !dbg !63
  ret i32 %1, !dbg !64
}

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2h3_select_iterlocal_invread_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "0e1b7baae057a4478e6b7719d156f459")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !13, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19, !21, !22, !23, !25, !26}
!17 = !DILocalVariable(name: "y", scope: !12, file: !8, line: 4, type: !15)
!18 = !DILocalVariable(name: "s", scope: !12, file: !8, line: 5, type: !15)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 6, type: !15)
!20 = distinct !DILexicalBlock(scope: !12, file: !8, line: 6, column: 5)
!21 = !DILocalVariable(name: "b", scope: !20, file: !8, line: 6, type: !10)
!22 = !DILocalVariable(name: "a", scope: !20, file: !8, line: 6, type: !15)
!23 = !DILocalVariable(name: "u", scope: !24, file: !8, line: 8, type: !15)
!24 = distinct !DILexicalBlock(scope: !12, file: !8, line: 8, column: 5)
!25 = !DILocalVariable(name: "b", scope: !24, file: !8, line: 8, type: !10)
!26 = !DILocalVariable(name: "a", scope: !24, file: !8, line: 8, type: !15)
!27 = !DILocation(line: 4, column: 13, scope: !12)
!28 = !DILocation(line: 0, scope: !12)
!29 = !DILocation(line: 6, column: 15, scope: !20)
!30 = !DILocation(line: 0, scope: !20)
!31 = !DILocation(line: 6, column: 42, scope: !20)
!32 = !DILocation(line: 6, column: 74, scope: !20)
!33 = !DILocation(line: 7, column: 12, scope: !20)
!34 = !DILocation(line: 7, column: 28, scope: !20)
!35 = !DILocation(line: 7, column: 55, scope: !20)
!36 = !DILocation(line: 8, column: 15, scope: !24)
!37 = !DILocation(line: 0, scope: !24)
!38 = !DILocation(line: 8, column: 42, scope: !24)
!39 = !DILocation(line: 8, column: 74, scope: !24)
!40 = !DILocation(line: 9, column: 12, scope: !24)
!41 = !DILocation(line: 9, column: 28, scope: !24)
!42 = !DILocation(line: 9, column: 55, scope: !24)
!43 = !DILocation(line: 10, column: 16, scope: !12)
!44 = !DILocation(line: 9, column: 26, scope: !24)
!45 = !DILocation(line: 9, column: 53, scope: !24)
!46 = !DILocation(line: 7, column: 26, scope: !20)
!47 = !DILocation(line: 7, column: 53, scope: !20)
!48 = !DILocation(line: 9, column: 9, scope: !24)
!49 = !DILocation(line: 10, column: 14, scope: !12)
!50 = !DILocation(line: 10, column: 5, scope: !12)
!51 = !DISubprogram(name: "cq_theta_si32", scope: !52, file: !52, line: 38, type: !53, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!52 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!53 = !DISubroutineType(types: !54)
!54 = !{!15, !15, !55}
!55 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!56 = !DISubprogram(name: "cq_theta_i1", scope: !52, file: !52, line: 32, type: !57, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!57 = !DISubroutineType(types: !58)
!58 = !{!10, !10, !55}
!59 = !DISubprogram(name: "cq_measure_si32", scope: !52, file: !52, line: 83, type: !60, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!60 = !DISubroutineType(types: !61)
!61 = !{!15, !15}
!62 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 12, type: !13, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!63 = !DILocation(line: 12, column: 25, scope: !62)
!64 = !DILocation(line: 12, column: 18, scope: !62)
