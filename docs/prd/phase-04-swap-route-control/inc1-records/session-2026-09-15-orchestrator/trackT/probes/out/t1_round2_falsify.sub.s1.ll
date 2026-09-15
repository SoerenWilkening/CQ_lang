; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t1_round2_falsify.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t1_round2_falsify.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !21
    #dbg_value(i32 %1, !15, !DIExpression(), !22)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 3.000000e-01) #2, !dbg !23
    #dbg_value(i32 %2, !16, !DIExpression(), !22)
  %3 = and i32 %1, 1, !dbg !24
  %4 = icmp eq i32 %3, 0, !dbg !24
  %5 = select i1 %4, i32 5, i32 2
    #dbg_value(i32 %5, !17, !DIExpression(), !22)
    #dbg_value(i32 0, !18, !DIExpression(), !22)
    #dbg_value(i32 1, !19, !DIExpression(), !26)
  br label %12, !dbg !27

6:                                                ; preds = %12
  %7 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2, !dbg !28
    #dbg_value(i32 %7, !16, !DIExpression(), !22)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !29
  %9 = add nsw i32 %8, %18, !dbg !30
  %10 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !31
  %11 = add nsw i32 %9, %10, !dbg !32
  ret i32 %11, !dbg !33

12:                                               ; preds = %0, %12
  %13 = phi i32 [ 1, %0 ], [ %19, %12 ]
  %14 = phi i32 [ 0, %0 ], [ %18, %12 ]
    #dbg_value(i32 %13, !19, !DIExpression(), !26)
    #dbg_value(i32 %14, !18, !DIExpression(), !22)
  %15 = ashr i32 %2, %13, !dbg !34
  %16 = and i32 %15, %5, !dbg !34
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #2, !dbg !34
  %18 = add nsw i32 %17, %14, !dbg !36
    #dbg_value(i32 %18, !18, !DIExpression(), !22)
  %19 = add nuw nsw i32 %13, 1, !dbg !37
    #dbg_value(i32 %19, !19, !DIExpression(), !26)
  %20 = icmp eq i32 %19, 3, !dbg !38
  br i1 %20, label %6, label %12, !dbg !27, !llvm.loop !39
}

declare !dbg !43 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !48 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !51 {
  %1 = tail call i32 @slice(), !dbg !52
  ret i32 %1, !dbg !53
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t1_round2_falsify.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "d5cdf402919d80a4c3a14656c0973b1b")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !19}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 11, type: !13)
!16 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 12, type: !13)
!17 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 13, type: !13)
!18 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 15, type: !13)
!19 = !DILocalVariable(name: "k", scope: !20, file: !8, line: 16, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 16, column: 5)
!21 = !DILocation(line: 11, column: 13, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 12, column: 13, scope: !10)
!24 = !DILocation(line: 14, column: 11, scope: !25)
!25 = distinct !DILexicalBlock(scope: !10, file: !8, line: 14, column: 9)
!26 = !DILocation(line: 0, scope: !20)
!27 = !DILocation(line: 16, column: 5, scope: !20)
!28 = !DILocation(line: 18, column: 9, scope: !10)
!29 = !DILocation(line: 19, column: 16, scope: !10)
!30 = !DILocation(line: 19, column: 14, scope: !10)
!31 = !DILocation(line: 19, column: 32, scope: !10)
!32 = !DILocation(line: 19, column: 30, scope: !10)
!33 = !DILocation(line: 19, column: 5, scope: !10)
!34 = !DILocation(line: 17, column: 14, scope: !35)
!35 = distinct !DILexicalBlock(scope: !20, file: !8, line: 16, column: 5)
!36 = !DILocation(line: 17, column: 11, scope: !35)
!37 = !DILocation(line: 16, column: 29, scope: !35)
!38 = !DILocation(line: 16, column: 23, scope: !35)
!39 = distinct !{!39, !27, !40, !41, !42}
!40 = !DILocation(line: 17, column: 14, scope: !20)
!41 = !{!"llvm.loop.mustprogress"}
!42 = !{!"llvm.loop.unroll.disable"}
!43 = !DISubprogram(name: "cq_theta_si32", scope: !44, file: !44, line: 38, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!45 = !DISubroutineType(types: !46)
!46 = !{!13, !13, !47}
!47 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!48 = !DISubprogram(name: "cq_measure_si32", scope: !44, file: !44, line: 83, type: !49, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!49 = !DISubroutineType(types: !50)
!50 = !{!13, !13}
!51 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 21, type: !11, scopeLine: 21, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!52 = !DILocation(line: 21, column: 25, scope: !51)
!53 = !DILocation(line: 21, column: 18, scope: !51)
