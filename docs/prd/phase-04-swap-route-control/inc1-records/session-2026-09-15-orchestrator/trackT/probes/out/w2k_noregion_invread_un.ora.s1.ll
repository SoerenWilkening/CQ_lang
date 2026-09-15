; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2k_noregion_invread_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2k_noregion_invread_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !21
    #dbg_value(i32 %1, !15, !DIExpression(), !22)
    #dbg_value(i32 0, !16, !DIExpression(), !22)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !23
    #dbg_value(i32 %2, !17, !DIExpression(), !24)
  %3 = lshr i32 %2, 1, !dbg !25
  %4 = and i32 %3, 1, !dbg !25
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2, !dbg !25
  %6 = and i32 %1, 1, !dbg !26
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !26
    #dbg_value(i32 poison, !16, !DIExpression(), !22)
  %8 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !27
    #dbg_value(i32 %8, !19, !DIExpression(), !28)
  %9 = lshr i32 %8, 1, !dbg !29
  %10 = and i32 %9, 1, !dbg !29
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !29
  %12 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !30
    #dbg_value(i32 %16, !16, !DIExpression(), !22)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !31
  %14 = add i32 %7, %5, !dbg !32
  %15 = add i32 %14, %11, !dbg !33
  %16 = add i32 %15, %12, !dbg !34
  %17 = add nsw i32 %16, %13, !dbg !35
  ret i32 %17, !dbg !36
}

declare !dbg !37 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !42 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !45 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !46
    #dbg_value(i32 %1, !15, !DIExpression(), !48)
    #dbg_value(i32 0, !16, !DIExpression(), !48)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !49
    #dbg_value(i32 %2, !17, !DIExpression(), !50)
  %3 = lshr i32 %2, 1, !dbg !51
  %4 = and i32 %3, 1, !dbg !51
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2, !dbg !51
  %6 = and i32 %1, 1, !dbg !52
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !52
    #dbg_value(i32 poison, !16, !DIExpression(), !48)
  %8 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !53
    #dbg_value(i32 %8, !19, !DIExpression(), !54)
  %9 = lshr i32 %8, 1, !dbg !55
  %10 = and i32 %9, 1, !dbg !55
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !55
  %12 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !56
    #dbg_value(i32 %16, !16, !DIExpression(), !48)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !57
  %14 = add i32 %7, %5, !dbg !58
  %15 = add i32 %14, %11, !dbg !59
  %16 = add i32 %15, %12, !dbg !60
  %17 = add nsw i32 %16, %13, !dbg !61
  ret i32 %17, !dbg !62
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2k_noregion_invread_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "6db310d92c366970cecf56763bded134")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocalVariable(name: "u", scope: !18, file: !8, line: 6, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 5)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 7, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 7, column: 5)
!21 = !DILocation(line: 4, column: 13, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 6, column: 15, scope: !18)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 6, column: 38, scope: !18)
!26 = !DILocation(line: 6, column: 65, scope: !18)
!27 = !DILocation(line: 7, column: 15, scope: !20)
!28 = !DILocation(line: 0, scope: !20)
!29 = !DILocation(line: 7, column: 38, scope: !20)
!30 = !DILocation(line: 7, column: 65, scope: !20)
!31 = !DILocation(line: 8, column: 16, scope: !10)
!32 = !DILocation(line: 7, column: 63, scope: !20)
!33 = !DILocation(line: 6, column: 63, scope: !18)
!34 = !DILocation(line: 7, column: 35, scope: !20)
!35 = !DILocation(line: 8, column: 14, scope: !10)
!36 = !DILocation(line: 8, column: 5, scope: !10)
!37 = !DISubprogram(name: "cq_theta_si32", scope: !38, file: !38, line: 38, type: !39, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!39 = !DISubroutineType(types: !40)
!40 = !{!13, !13, !41}
!41 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!42 = !DISubprogram(name: "cq_measure_si32", scope: !38, file: !38, line: 83, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DISubroutineType(types: !44)
!44 = !{!13, !13}
!45 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!46 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !47)
!47 = distinct !DILocation(line: 10, column: 25, scope: !45)
!48 = !DILocation(line: 0, scope: !10, inlinedAt: !47)
!49 = !DILocation(line: 6, column: 15, scope: !18, inlinedAt: !47)
!50 = !DILocation(line: 0, scope: !18, inlinedAt: !47)
!51 = !DILocation(line: 6, column: 38, scope: !18, inlinedAt: !47)
!52 = !DILocation(line: 6, column: 65, scope: !18, inlinedAt: !47)
!53 = !DILocation(line: 7, column: 15, scope: !20, inlinedAt: !47)
!54 = !DILocation(line: 0, scope: !20, inlinedAt: !47)
!55 = !DILocation(line: 7, column: 38, scope: !20, inlinedAt: !47)
!56 = !DILocation(line: 7, column: 65, scope: !20, inlinedAt: !47)
!57 = !DILocation(line: 8, column: 16, scope: !10, inlinedAt: !47)
!58 = !DILocation(line: 7, column: 63, scope: !20, inlinedAt: !47)
!59 = !DILocation(line: 6, column: 63, scope: !18, inlinedAt: !47)
!60 = !DILocation(line: 7, column: 35, scope: !20, inlinedAt: !47)
!61 = !DILocation(line: 8, column: 14, scope: !10, inlinedAt: !47)
!62 = !DILocation(line: 10, column: 18, scope: !45)
