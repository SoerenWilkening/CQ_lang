; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a6_k1.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a6_k1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !19
    #dbg_value(i32 %1, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 1, !17, !DIExpression(), !21)
    #dbg_value(i32 poison, !17, !DIExpression(), !21)
  %2 = lshr i32 %1, 1
  %3 = and i32 %2, 1
    #dbg_value(i32 0, !16, !DIExpression(), !20)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !22
    #dbg_value(i32 poison, !17, !DIExpression(), !21)
    #dbg_value(i32 %4, !16, !DIExpression(), !20)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !24
    #dbg_value(i32 %5, !15, !DIExpression(), !20)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !25
  %7 = add nsw i32 %6, %4, !dbg !26
  ret i32 %7, !dbg !27
}

declare !dbg !28 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !33 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !36 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !37
    #dbg_value(i32 %1, !15, !DIExpression(), !39)
    #dbg_value(i32 0, !16, !DIExpression(), !39)
    #dbg_value(i32 1, !17, !DIExpression(), !40)
    #dbg_value(i32 poison, !17, !DIExpression(), !40)
  %2 = lshr i32 %1, 1
  %3 = and i32 %2, 1
    #dbg_value(i32 0, !16, !DIExpression(), !39)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !41
    #dbg_value(i32 poison, !17, !DIExpression(), !40)
    #dbg_value(i32 %4, !16, !DIExpression(), !39)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !42
    #dbg_value(i32 %5, !15, !DIExpression(), !39)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !43
  %7 = add nsw i32 %6, %4, !dbg !44
  ret i32 %7, !dbg !45
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a6_k1.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "766f25a2e60be322854566360c5f6ad8")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 6, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 5)
!19 = !DILocation(line: 4, column: 13, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 7, column: 14, scope: !23)
!23 = distinct !DILexicalBlock(scope: !18, file: !8, line: 6, column: 5)
!24 = !DILocation(line: 8, column: 9, scope: !10)
!25 = !DILocation(line: 9, column: 16, scope: !10)
!26 = !DILocation(line: 9, column: 14, scope: !10)
!27 = !DILocation(line: 9, column: 5, scope: !10)
!28 = !DISubprogram(name: "cq_theta_si32", scope: !29, file: !29, line: 38, type: !30, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!29 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!30 = !DISubroutineType(types: !31)
!31 = !{!13, !13, !32}
!32 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!33 = !DISubprogram(name: "cq_measure_si32", scope: !29, file: !29, line: 83, type: !34, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!34 = !DISubroutineType(types: !35)
!35 = !{!13, !13}
!36 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !11, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!37 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !38)
!38 = distinct !DILocation(line: 11, column: 25, scope: !36)
!39 = !DILocation(line: 0, scope: !10, inlinedAt: !38)
!40 = !DILocation(line: 0, scope: !18, inlinedAt: !38)
!41 = !DILocation(line: 7, column: 14, scope: !23, inlinedAt: !38)
!42 = !DILocation(line: 8, column: 9, scope: !10, inlinedAt: !38)
!43 = !DILocation(line: 9, column: 16, scope: !10, inlinedAt: !38)
!44 = !DILocation(line: 9, column: 14, scope: !10, inlinedAt: !38)
!45 = !DILocation(line: 11, column: 18, scope: !36)
