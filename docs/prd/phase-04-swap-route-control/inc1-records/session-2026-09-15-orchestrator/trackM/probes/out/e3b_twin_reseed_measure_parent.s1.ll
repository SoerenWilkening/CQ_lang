; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3b_twin_reseed_measure_parent.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3b_twin_reseed_measure_parent.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !19
    #dbg_value(i32 %1, !15, !DIExpression(), !20)
  %2 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !21
    #dbg_value(i32 %2, !16, !DIExpression(), !20)
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i32 %3, !17, !DIExpression(), !20)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !23
    #dbg_value(i32 %4, !18, !DIExpression(), !20)
  %5 = add nsw i32 %4, %2, !dbg !24
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !25
  %7 = add nsw i32 %5, %6, !dbg !26
  ret i32 %7, !dbg !27
}

declare !dbg !28 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !33 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3b_twin_reseed_measure_parent.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e0f079245f42deba6bbd7f623b69973e")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "m", scope: !10, file: !8, line: 6, type: !13)
!17 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 6, type: !13)
!18 = !DILocalVariable(name: "m2", scope: !10, file: !8, line: 6, type: !13)
!19 = !DILocation(line: 6, column: 23, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 6, column: 46, scope: !10)
!22 = !DILocation(line: 6, column: 67, scope: !10)
!23 = !DILocation(line: 6, column: 91, scope: !10)
!24 = !DILocation(line: 6, column: 114, scope: !10)
!25 = !DILocation(line: 6, column: 118, scope: !10)
!26 = !DILocation(line: 6, column: 117, scope: !10)
!27 = !DILocation(line: 6, column: 106, scope: !10)
!28 = !DISubprogram(name: "cq_theta_si32", scope: !29, file: !29, line: 38, type: !30, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!29 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!30 = !DISubroutineType(types: !31)
!31 = !{!13, !13, !32}
!32 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!33 = !DISubprogram(name: "cq_measure_si32", scope: !29, file: !29, line: 83, type: !34, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!34 = !DISubroutineType(types: !35)
!35 = !{!13, !13}
