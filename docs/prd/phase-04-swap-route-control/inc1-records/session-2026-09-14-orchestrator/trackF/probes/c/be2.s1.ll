; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/be2.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/be2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 3.000000e-01) #2, !dbg !18
    #dbg_value(i32 %1, !15, !DIExpression(), !19)
    #dbg_value(i32 0, !16, !DIExpression(), !19)
    #dbg_value(i32 0, !17, !DIExpression(), !19)
  %2 = icmp eq i32 %1, 5, !dbg !20
  br i1 %2, label %3, label %5, !dbg !22

3:                                                ; preds = %0
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 9.000000e-01) #2, !dbg !23
    #dbg_value(i32 %4, !17, !DIExpression(), !19)
  br label %5, !dbg !24

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 0, %0 ], !dbg !19
    #dbg_value(i32 %6, !17, !DIExpression(), !19)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !25
  %8 = tail call i32 @cq_measure_si32(i32 noundef 0) #2, !dbg !26
  %9 = add nsw i32 %8, %7, !dbg !27
  %10 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !28
  %11 = add nsw i32 %9, %10, !dbg !29
  ret i32 %11, !dbg !30
}

declare !dbg !31 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !36 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/be2.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "40ca9cf7f515ec47932ce8d9e412eec2")
!9 = !{!10}
!10 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 2, type: !13, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!13 = !DISubroutineType(types: !9)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "q", scope: !12, file: !8, line: 2, type: !10)
!16 = !DILocalVariable(name: "t", scope: !12, file: !8, line: 2, type: !10)
!17 = !DILocalVariable(name: "r", scope: !12, file: !8, line: 2, type: !10)
!18 = !DILocation(line: 2, column: 25, scope: !12)
!19 = !DILocation(line: 0, scope: !12)
!20 = !DILocation(line: 3, column: 9, scope: !21)
!21 = distinct !DILexicalBlock(scope: !12, file: !8, line: 3, column: 7)
!22 = !DILocation(line: 3, column: 7, scope: !12)
!23 = !DILocation(line: 3, column: 19, scope: !21)
!24 = !DILocation(line: 3, column: 15, scope: !21)
!25 = !DILocation(line: 4, column: 15, scope: !12)
!26 = !DILocation(line: 4, column: 36, scope: !12)
!27 = !DILocation(line: 4, column: 29, scope: !12)
!28 = !DILocation(line: 4, column: 57, scope: !12)
!29 = !DILocation(line: 4, column: 50, scope: !12)
!30 = !DILocation(line: 4, column: 3, scope: !12)
!31 = !DISubprogram(name: "cq_theta_si32", scope: !32, file: !32, line: 38, type: !33, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!32 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!33 = !DISubroutineType(types: !34)
!34 = !{!10, !10, !35}
!35 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!36 = !DISubprogram(name: "cq_measure_si32", scope: !32, file: !32, line: 83, type: !37, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DISubroutineType(types: !38)
!38 = !{!10, !10}
