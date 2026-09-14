; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a4_invariant_measured_and_read_after_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a4_invariant_measured_and_read_after_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !18
    #dbg_value(i32 %1, !15, !DIExpression(), !19)
  %2 = and i32 %1, 1, !dbg !20
    #dbg_value(i32 %2, !16, !DIExpression(), !19)
    #dbg_value(i32 0, !17, !DIExpression(), !19)
  %3 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !21
  %4 = lshr i32 %1, 1, !dbg !22
  %5 = and i32 %4, 1, !dbg !22
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !22
    #dbg_value(i32 poison, !17, !DIExpression(), !19)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !23
  %8 = lshr i32 %1, 2, !dbg !24
  %9 = and i32 %8, 1, !dbg !24
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !24
    #dbg_value(i32 %17, !17, !DIExpression(), !19)
  %11 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !25
    #dbg_value(i32 %11, !15, !DIExpression(), !19)
  %12 = add nuw nsw i32 %2, 1, !dbg !26
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !26
  %14 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !27
  %15 = add i32 %6, %3, !dbg !28
  %16 = add i32 %15, %7, !dbg !29
  %17 = add i32 %16, %10, !dbg !30
  %18 = add nsw i32 %17, %13, !dbg !31
  %19 = add nsw i32 %18, %14, !dbg !32
  ret i32 %19, !dbg !33
}

declare !dbg !34 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !39 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !42 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !43
    #dbg_value(i32 %1, !15, !DIExpression(), !45)
  %2 = and i32 %1, 1, !dbg !46
    #dbg_value(i32 %2, !16, !DIExpression(), !45)
    #dbg_value(i32 0, !17, !DIExpression(), !45)
  %3 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !47
  %4 = lshr i32 %1, 1, !dbg !48
  %5 = and i32 %4, 1, !dbg !48
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !48
    #dbg_value(i32 poison, !17, !DIExpression(), !45)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !49
  %8 = lshr i32 %1, 2, !dbg !50
  %9 = and i32 %8, 1, !dbg !50
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !50
    #dbg_value(i32 %17, !17, !DIExpression(), !45)
  %11 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !51
    #dbg_value(i32 %11, !15, !DIExpression(), !45)
  %12 = add nuw nsw i32 %2, 1, !dbg !52
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !52
  %14 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !53
  %15 = add i32 %6, %3, !dbg !54
  %16 = add i32 %15, %7, !dbg !55
  %17 = add i32 %16, %10, !dbg !56
  %18 = add nsw i32 %17, %13, !dbg !57
  %19 = add nsw i32 %18, %14, !dbg !58
  ret i32 %19, !dbg !59
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a4_invariant_measured_and_read_after_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "360f96945f69461dbc80c062847a7665")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!18 = !DILocation(line: 3, column: 13, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 4, column: 15, scope: !10)
!21 = !DILocation(line: 6, column: 10, scope: !10)
!22 = !DILocation(line: 6, column: 26, scope: !10)
!23 = !DILocation(line: 7, column: 10, scope: !10)
!24 = !DILocation(line: 7, column: 26, scope: !10)
!25 = !DILocation(line: 8, column: 9, scope: !10)
!26 = !DILocation(line: 9, column: 16, scope: !10)
!27 = !DILocation(line: 9, column: 36, scope: !10)
!28 = !DILocation(line: 7, column: 24, scope: !10)
!29 = !DILocation(line: 6, column: 24, scope: !10)
!30 = !DILocation(line: 7, column: 7, scope: !10)
!31 = !DILocation(line: 9, column: 14, scope: !10)
!32 = !DILocation(line: 9, column: 34, scope: !10)
!33 = !DILocation(line: 9, column: 5, scope: !10)
!34 = !DISubprogram(name: "cq_theta_si32", scope: !35, file: !35, line: 38, type: !36, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!35 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!36 = !DISubroutineType(types: !37)
!37 = !{!13, !13, !38}
!38 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!39 = !DISubprogram(name: "cq_measure_si32", scope: !35, file: !35, line: 83, type: !40, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!40 = !DISubroutineType(types: !41)
!41 = !{!13, !13}
!42 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !11, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!43 = !DILocation(line: 3, column: 13, scope: !10, inlinedAt: !44)
!44 = distinct !DILocation(line: 11, column: 25, scope: !42)
!45 = !DILocation(line: 0, scope: !10, inlinedAt: !44)
!46 = !DILocation(line: 4, column: 15, scope: !10, inlinedAt: !44)
!47 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !44)
!48 = !DILocation(line: 6, column: 26, scope: !10, inlinedAt: !44)
!49 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !44)
!50 = !DILocation(line: 7, column: 26, scope: !10, inlinedAt: !44)
!51 = !DILocation(line: 8, column: 9, scope: !10, inlinedAt: !44)
!52 = !DILocation(line: 9, column: 16, scope: !10, inlinedAt: !44)
!53 = !DILocation(line: 9, column: 36, scope: !10, inlinedAt: !44)
!54 = !DILocation(line: 7, column: 24, scope: !10, inlinedAt: !44)
!55 = !DILocation(line: 6, column: 24, scope: !10, inlinedAt: !44)
!56 = !DILocation(line: 7, column: 7, scope: !10, inlinedAt: !44)
!57 = !DILocation(line: 9, column: 14, scope: !10, inlinedAt: !44)
!58 = !DILocation(line: 9, column: 34, scope: !10, inlinedAt: !44)
!59 = !DILocation(line: 11, column: 18, scope: !42)
