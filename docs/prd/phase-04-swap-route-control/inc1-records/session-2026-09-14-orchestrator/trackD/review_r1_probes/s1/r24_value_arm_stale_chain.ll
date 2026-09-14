; ModuleID = 'src/r24_value_arm_stale_chain.c'
source_filename = "src/r24_value_arm_stale_chain.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !19)
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2, !dbg !20
    #dbg_value(i32 %2, !16, !DIExpression(), !19)
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #2, !dbg !21
    #dbg_value(i32 %3, !17, !DIExpression(), !19)
    #dbg_value(i32 7, !18, !DIExpression(), !19)
  %4 = icmp eq i32 %0, 4, !dbg !22
  %5 = add nsw i32 %2, 1
  %6 = select i1 %4, i32 %5, i32 7, !dbg !24
    #dbg_value(i32 %6, !18, !DIExpression(), !19)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !25
  %8 = add nsw i32 %7, %6, !dbg !26
  ret i32 %8, !dbg !27
}

declare !dbg !28 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !33 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !34 {
    #dbg_value(i32 4, !15, !DIExpression(), !37)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 4, double noundef 5.000000e-01) #2, !dbg !39
    #dbg_value(i32 %1, !16, !DIExpression(), !37)
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2, !dbg !40
    #dbg_value(i32 %2, !17, !DIExpression(), !37)
    #dbg_value(i32 7, !18, !DIExpression(), !37)
  %3 = add nsw i32 %1, 1
    #dbg_value(i32 %3, !18, !DIExpression(), !37)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !41
  %5 = add nsw i32 %3, %4, !dbg !42
  ret i32 %5, !dbg !43
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
!8 = !DIFile(filename: "src/r24_value_arm_stale_chain.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes", checksumkind: CSK_MD5, checksum: "41980269ce523ef58d0f88a1b3462635")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "u", arg: 1, scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 3, type: !13)
!18 = !DILocalVariable(name: "r", scope: !10, file: !8, line: 3, type: !13)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 3, column: 25, scope: !10)
!21 = !DILocation(line: 3, column: 48, scope: !10)
!22 = !DILocation(line: 4, column: 7, scope: !23)
!23 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 6)
!24 = !DILocation(line: 4, column: 6, scope: !10)
!25 = !DILocation(line: 5, column: 10, scope: !10)
!26 = !DILocation(line: 5, column: 23, scope: !10)
!27 = !DILocation(line: 5, column: 3, scope: !10)
!28 = !DISubprogram(name: "cq_theta_si32", scope: !29, file: !29, line: 38, type: !30, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!29 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!30 = !DISubroutineType(types: !31)
!31 = !{!13, !13, !32}
!32 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!33 = !DISubprogram(name: "cq_measure_si32", scope: !29, file: !29, line: 83, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!34 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 6, type: !35, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!35 = !DISubroutineType(types: !36)
!36 = !{!13}
!37 = !DILocation(line: 0, scope: !10, inlinedAt: !38)
!38 = distinct !DILocation(line: 6, column: 24, scope: !34)
!39 = !DILocation(line: 3, column: 25, scope: !10, inlinedAt: !38)
!40 = !DILocation(line: 3, column: 48, scope: !10, inlinedAt: !38)
!41 = !DILocation(line: 5, column: 10, scope: !10, inlinedAt: !38)
!42 = !DILocation(line: 5, column: 23, scope: !10, inlinedAt: !38)
!43 = !DILocation(line: 6, column: 17, scope: !34)
