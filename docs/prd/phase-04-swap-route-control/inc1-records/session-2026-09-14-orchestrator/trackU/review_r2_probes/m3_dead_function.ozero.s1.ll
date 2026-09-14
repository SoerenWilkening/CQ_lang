; ModuleID = 'm3_dead_function.zero.c'
source_filename = "m3_dead_function.zero.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @dead_one() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !16)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 7.500000e-01) #2, !dbg !17
  ret i32 %1, !dbg !18
}

declare !dbg !19 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !24 {
    #dbg_value(i32 0, !26, !DIExpression(), !27)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2, !dbg !28
    #dbg_value(i32 %1, !26, !DIExpression(), !27)
  %2 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !29
  ret i32 %2, !dbg !30
}

declare !dbg !31 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "m3_dead_function.zero.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r2_probes", checksumkind: CSK_MD5, checksum: "74dec625989d812c6bd1fbf81502c670")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "dead_one", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15}
!15 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocation(line: 0, scope: !10)
!17 = !DILocation(line: 3, column: 40, scope: !10)
!18 = !DILocation(line: 3, column: 33, scope: !10)
!19 = !DISubprogram(name: "cq_theta_si32", scope: !20, file: !20, line: 38, type: !21, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!20 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!21 = !DISubroutineType(types: !22)
!22 = !{!13, !13, !23}
!23 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!24 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !25)
!25 = !{!26}
!26 = !DILocalVariable(name: "t", scope: !24, file: !8, line: 4, type: !13)
!27 = !DILocation(line: 0, scope: !24)
!28 = !DILocation(line: 4, column: 33, scope: !24)
!29 = !DILocation(line: 4, column: 58, scope: !24)
!30 = !DILocation(line: 4, column: 51, scope: !24)
!31 = !DISubprogram(name: "cq_measure_si32", scope: !20, file: !20, line: 83, type: !32, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!32 = !DISubroutineType(types: !33)
!33 = !{!13, !13}
