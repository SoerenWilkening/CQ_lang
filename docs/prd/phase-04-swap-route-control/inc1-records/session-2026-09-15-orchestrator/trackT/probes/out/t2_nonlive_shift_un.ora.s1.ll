; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t2_nonlive_shift_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t2_nonlive_shift_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !17
    #dbg_value(i32 %1, !15, !DIExpression(), !18)
    #dbg_value(i32 0, !16, !DIExpression(), !18)
  %2 = lshr i32 %1, 1, !dbg !19
  %3 = and i32 %2, 1, !dbg !19
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !19
    #dbg_value(i32 %4, !16, !DIExpression(), !18)
  %5 = lshr i32 %1, 2, !dbg !20
  %6 = and i32 %5, 1, !dbg !20
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !20
  %8 = add nsw i32 %7, %4, !dbg !21
    #dbg_value(i32 %8, !16, !DIExpression(), !18)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !22
  %10 = add nsw i32 %8, %9, !dbg !23
  ret i32 %10, !dbg !24
}

declare !dbg !25 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !30 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !33 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !34
    #dbg_value(i32 %1, !15, !DIExpression(), !36)
    #dbg_value(i32 0, !16, !DIExpression(), !36)
  %2 = lshr i32 %1, 1, !dbg !37
  %3 = and i32 %2, 1, !dbg !37
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !37
    #dbg_value(i32 %4, !16, !DIExpression(), !36)
  %5 = lshr i32 %1, 2, !dbg !38
  %6 = and i32 %5, 1, !dbg !38
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !38
  %8 = add nsw i32 %7, %4, !dbg !39
    #dbg_value(i32 %8, !16, !DIExpression(), !36)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !40
  %10 = add nsw i32 %8, %9, !dbg !41
  ret i32 %10, !dbg !42
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t2_nonlive_shift_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "b6232af7709449d91f8187f25d87f407")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocation(line: 4, column: 13, scope: !10)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 6, column: 10, scope: !10)
!20 = !DILocation(line: 7, column: 10, scope: !10)
!21 = !DILocation(line: 7, column: 7, scope: !10)
!22 = !DILocation(line: 8, column: 16, scope: !10)
!23 = !DILocation(line: 8, column: 14, scope: !10)
!24 = !DILocation(line: 8, column: 5, scope: !10)
!25 = !DISubprogram(name: "cq_theta_si32", scope: !26, file: !26, line: 38, type: !27, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!26 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!27 = !DISubroutineType(types: !28)
!28 = !{!13, !13, !29}
!29 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!30 = !DISubprogram(name: "cq_measure_si32", scope: !26, file: !26, line: 83, type: !31, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!31 = !DISubroutineType(types: !32)
!32 = !{!13, !13}
!33 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!34 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !35)
!35 = distinct !DILocation(line: 10, column: 25, scope: !33)
!36 = !DILocation(line: 0, scope: !10, inlinedAt: !35)
!37 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !35)
!38 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !35)
!39 = !DILocation(line: 7, column: 7, scope: !10, inlinedAt: !35)
!40 = !DILocation(line: 8, column: 16, scope: !10, inlinedAt: !35)
!41 = !DILocation(line: 8, column: 14, scope: !10, inlinedAt: !35)
!42 = !DILocation(line: 10, column: 18, scope: !33)
