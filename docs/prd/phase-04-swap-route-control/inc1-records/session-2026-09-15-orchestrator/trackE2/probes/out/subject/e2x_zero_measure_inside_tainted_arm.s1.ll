; ModuleID = 'src/e2x_zero_measure_inside_tainted_arm.c'
source_filename = "src/e2x_zero_measure_inside_tainted_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !18)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !19
    #dbg_value(i32 %1, !16, !DIExpression(), !18)
    #dbg_value(i32 1, !17, !DIExpression(), !18)
  %2 = icmp eq i32 %1, 3, !dbg !20
  br i1 %2, label %3, label %6, !dbg !22

3:                                                ; preds = %0
  %4 = tail call i32 @cq_measure_si32(i32 noundef 0) #2, !dbg !23
  %5 = add nsw i32 %4, 2, !dbg !25
    #dbg_value(i32 %5, !17, !DIExpression(), !18)
  br label %6, !dbg !26

6:                                                ; preds = %3, %0
  %7 = phi i32 [ %5, %3 ], [ 1, %0 ], !dbg !27
    #dbg_value(i32 %7, !17, !DIExpression(), !18)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !28
  %9 = add nsw i32 %8, %7, !dbg !29
  ret i32 %9, !dbg !30
}

declare !dbg !31 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !36 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/e2x_zero_measure_inside_tainted_arm.c", directory: "/Users/sorenwilkening/Desktop/CQ_E2/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackE2/probes", checksumkind: CSK_MD5, checksum: "23a96b9dbd981d393c32168c03469b19")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "u", scope: !10, file: !8, line: 2, type: !13)
!16 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 2, type: !13)
!17 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 2, type: !13)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 2, column: 36, scope: !10)
!20 = !DILocation(line: 2, column: 71, scope: !21)
!21 = distinct !DILexicalBlock(scope: !10, file: !8, line: 2, column: 69)
!22 = !DILocation(line: 2, column: 69, scope: !10)
!23 = !DILocation(line: 2, column: 83, scope: !24)
!24 = distinct !DILexicalBlock(scope: !21, file: !8, line: 2, column: 77)
!25 = !DILocation(line: 2, column: 97, scope: !24)
!26 = !DILocation(line: 2, column: 102, scope: !24)
!27 = !DILocation(line: 2, scope: !10)
!28 = !DILocation(line: 2, column: 111, scope: !10)
!29 = !DILocation(line: 2, column: 125, scope: !10)
!30 = !DILocation(line: 2, column: 104, scope: !10)
!31 = !DISubprogram(name: "cq_theta_si32", scope: !32, file: !32, line: 38, type: !33, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!32 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_E2", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!33 = !DISubroutineType(types: !34)
!34 = !{!13, !13, !35}
!35 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!36 = !DISubprogram(name: "cq_measure_si32", scope: !32, file: !32, line: 83, type: !37, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DISubroutineType(types: !38)
!38 = !{!13, !13}
