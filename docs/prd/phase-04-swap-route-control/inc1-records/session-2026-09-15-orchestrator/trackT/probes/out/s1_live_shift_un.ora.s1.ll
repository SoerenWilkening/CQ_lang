; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/s1_live_shift_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/s1_live_shift_un.c"
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
  %9 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !22
    #dbg_value(i32 %9, !15, !DIExpression(), !18)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !23
  %11 = add nsw i32 %8, %10, !dbg !24
  ret i32 %11, !dbg !25
}

declare !dbg !26 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !31 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !34 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !35
    #dbg_value(i32 %1, !15, !DIExpression(), !37)
    #dbg_value(i32 0, !16, !DIExpression(), !37)
  %2 = lshr i32 %1, 1, !dbg !38
  %3 = and i32 %2, 1, !dbg !38
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !38
    #dbg_value(i32 %4, !16, !DIExpression(), !37)
  %5 = lshr i32 %1, 2, !dbg !39
  %6 = and i32 %5, 1, !dbg !39
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !39
  %8 = add nsw i32 %7, %4, !dbg !40
    #dbg_value(i32 %8, !16, !DIExpression(), !37)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !41
    #dbg_value(i32 %9, !15, !DIExpression(), !37)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !42
  %11 = add nsw i32 %8, %10, !dbg !43
  ret i32 %11, !dbg !44
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/s1_live_shift_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "7ade4edbb8ebd7f88ad4c8fe5b7bbbe1")
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
!22 = !DILocation(line: 8, column: 9, scope: !10)
!23 = !DILocation(line: 9, column: 16, scope: !10)
!24 = !DILocation(line: 9, column: 14, scope: !10)
!25 = !DILocation(line: 9, column: 5, scope: !10)
!26 = !DISubprogram(name: "cq_theta_si32", scope: !27, file: !27, line: 38, type: !28, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!27 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!28 = !DISubroutineType(types: !29)
!29 = !{!13, !13, !30}
!30 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!31 = !DISubprogram(name: "cq_measure_si32", scope: !27, file: !27, line: 83, type: !32, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!32 = !DISubroutineType(types: !33)
!33 = !{!13, !13}
!34 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !11, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!35 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !36)
!36 = distinct !DILocation(line: 11, column: 25, scope: !34)
!37 = !DILocation(line: 0, scope: !10, inlinedAt: !36)
!38 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !36)
!39 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !36)
!40 = !DILocation(line: 7, column: 7, scope: !10, inlinedAt: !36)
!41 = !DILocation(line: 8, column: 9, scope: !10, inlinedAt: !36)
!42 = !DILocation(line: 9, column: 16, scope: !10, inlinedAt: !36)
!43 = !DILocation(line: 9, column: 14, scope: !10, inlinedAt: !36)
!44 = !DILocation(line: 11, column: 18, scope: !34)
