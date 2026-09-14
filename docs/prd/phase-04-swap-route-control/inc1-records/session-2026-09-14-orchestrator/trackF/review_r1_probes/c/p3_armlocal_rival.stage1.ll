; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p3_armlocal_rival.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p3_armlocal_rival.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !21
    #dbg_value(i32 %1, !16, !DIExpression(), !22)
    #dbg_value(i32 0, !17, !DIExpression(), !22)
  %2 = icmp eq i32 %1, -7, !dbg !23
  br i1 %2, label %3, label %5, !dbg !24

3:                                                ; preds = %0
    #dbg_value(i32 0, !18, !DIExpression(), !25)
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2, !dbg !26
    #dbg_value(i32 %4, !17, !DIExpression(), !22)
  br label %5, !dbg !27

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 0, %0 ], !dbg !22
    #dbg_value(i32 %6, !17, !DIExpression(), !22)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !28
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !29
  %9 = add nsw i32 %8, %7, !dbg !30
  ret i32 %9, !dbg !31
}

declare !dbg !32 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !37 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p3_armlocal_rival.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "a4562279549458ebe2ee3247209f8a43")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 5, type: !12, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p3_armlocal_rival.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "a4562279549458ebe2ee3247209f8a43")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18}
!16 = !DILocalVariable(name: "q", scope: !10, file: !11, line: 6, type: !14)
!17 = !DILocalVariable(name: "r", scope: !10, file: !11, line: 7, type: !14)
!18 = !DILocalVariable(name: "w", scope: !19, file: !11, line: 8, type: !14)
!19 = distinct !DILexicalBlock(scope: !20, file: !11, line: 8, column: 18)
!20 = distinct !DILexicalBlock(scope: !10, file: !11, line: 8, column: 9)
!21 = !DILocation(line: 6, column: 13, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 8, column: 11, scope: !20)
!24 = !DILocation(line: 8, column: 9, scope: !10)
!25 = !DILocation(line: 0, scope: !19)
!26 = !DILocation(line: 8, column: 39, scope: !19)
!27 = !DILocation(line: 8, column: 57, scope: !19)
!28 = !DILocation(line: 9, column: 12, scope: !10)
!29 = !DILocation(line: 9, column: 28, scope: !10)
!30 = !DILocation(line: 9, column: 26, scope: !10)
!31 = !DILocation(line: 9, column: 5, scope: !10)
!32 = !DISubprogram(name: "cq_theta_si32", scope: !33, file: !33, line: 38, type: !34, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!33 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!34 = !DISubroutineType(types: !35)
!35 = !{!14, !14, !36}
!36 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!37 = !DISubprogram(name: "cq_measure_si32", scope: !33, file: !33, line: 83, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = !DISubroutineType(types: !39)
!39 = !{!14, !14}
