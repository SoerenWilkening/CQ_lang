; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a2_fanout_body_rail.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a2_fanout_body_rail.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i32 %1, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 1, !17, !DIExpression(), !24)
  br label %6, !dbg !25

2:                                                ; preds = %6
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !26
    #dbg_value(i32 %3, !15, !DIExpression(), !23)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !27
  %5 = add nsw i32 %4, %15, !dbg !28
  ret i32 %5, !dbg !29

6:                                                ; preds = %0, %6
  %7 = phi i32 [ 1, %0 ], [ %16, %6 ]
  %8 = phi i32 [ 0, %0 ], [ %15, %6 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !24)
    #dbg_value(i32 %8, !16, !DIExpression(), !23)
  %9 = ashr i32 %1, %7, !dbg !30
    #dbg_value(i32 %9, !19, !DIExpression(), !31)
  %10 = and i32 %9, 1, !dbg !32
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !32
  %12 = and i32 %9, 2, !dbg !33
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !33
  %14 = add i32 %11, %8, !dbg !34
  %15 = add i32 %14, %13, !dbg !35
    #dbg_value(i32 %15, !16, !DIExpression(), !23)
  %16 = add nuw nsw i32 %7, 1, !dbg !36
    #dbg_value(i32 %16, !17, !DIExpression(), !24)
  %17 = icmp eq i32 %16, 3, !dbg !37
  br i1 %17, label %2, label %6, !dbg !25, !llvm.loop !38
}

declare !dbg !42 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !47 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !50 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !51
    #dbg_value(i32 %1, !15, !DIExpression(), !53)
    #dbg_value(i32 0, !16, !DIExpression(), !53)
    #dbg_value(i32 1, !17, !DIExpression(), !54)
  br label %2, !dbg !55

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %12, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %11, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !54)
    #dbg_value(i32 %4, !16, !DIExpression(), !53)
  %5 = ashr i32 %1, %3, !dbg !56
    #dbg_value(i32 %5, !19, !DIExpression(), !57)
  %6 = and i32 %5, 1, !dbg !58
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !58
  %8 = and i32 %5, 2, !dbg !59
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !59
  %10 = add i32 %7, %4, !dbg !60
  %11 = add i32 %10, %9, !dbg !61
    #dbg_value(i32 %11, !16, !DIExpression(), !53)
  %12 = add nuw nsw i32 %3, 1, !dbg !62
    #dbg_value(i32 %12, !17, !DIExpression(), !54)
  %13 = icmp eq i32 %12, 3, !dbg !63
  br i1 %13, label %14, label %2, !dbg !55, !llvm.loop !64

14:                                               ; preds = %2
  %15 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !66
    #dbg_value(i32 %15, !15, !DIExpression(), !53)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !67
  %17 = add nsw i32 %16, %11, !dbg !68
  ret i32 %17, !dbg !69
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a2_fanout_body_rail.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "278cd02483560693c354553fba660cdf")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 8, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!19 = !DILocalVariable(name: "t", scope: !20, file: !8, line: 9, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 8, column: 34)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!22 = !DILocation(line: 6, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 8, column: 5, scope: !18)
!26 = !DILocation(line: 12, column: 9, scope: !10)
!27 = !DILocation(line: 13, column: 16, scope: !10)
!28 = !DILocation(line: 13, column: 14, scope: !10)
!29 = !DILocation(line: 13, column: 5, scope: !10)
!30 = !DILocation(line: 9, column: 19, scope: !20)
!31 = !DILocation(line: 0, scope: !20)
!32 = !DILocation(line: 10, column: 14, scope: !20)
!33 = !DILocation(line: 10, column: 34, scope: !20)
!34 = !DILocation(line: 10, column: 32, scope: !20)
!35 = !DILocation(line: 10, column: 11, scope: !20)
!36 = !DILocation(line: 8, column: 29, scope: !21)
!37 = !DILocation(line: 8, column: 23, scope: !21)
!38 = distinct !{!38, !25, !39, !40, !41}
!39 = !DILocation(line: 11, column: 5, scope: !18)
!40 = !{!"llvm.loop.mustprogress"}
!41 = !{!"llvm.loop.unroll.disable"}
!42 = !DISubprogram(name: "cq_theta_si32", scope: !43, file: !43, line: 38, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!44 = !DISubroutineType(types: !45)
!45 = !{!13, !13, !46}
!46 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!47 = !DISubprogram(name: "cq_measure_si32", scope: !43, file: !43, line: 83, type: !48, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!48 = !DISubroutineType(types: !49)
!49 = !{!13, !13}
!50 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!51 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !52)
!52 = distinct !DILocation(line: 15, column: 25, scope: !50)
!53 = !DILocation(line: 0, scope: !10, inlinedAt: !52)
!54 = !DILocation(line: 0, scope: !18, inlinedAt: !52)
!55 = !DILocation(line: 8, column: 5, scope: !18, inlinedAt: !52)
!56 = !DILocation(line: 9, column: 19, scope: !20, inlinedAt: !52)
!57 = !DILocation(line: 0, scope: !20, inlinedAt: !52)
!58 = !DILocation(line: 10, column: 14, scope: !20, inlinedAt: !52)
!59 = !DILocation(line: 10, column: 34, scope: !20, inlinedAt: !52)
!60 = !DILocation(line: 10, column: 32, scope: !20, inlinedAt: !52)
!61 = !DILocation(line: 10, column: 11, scope: !20, inlinedAt: !52)
!62 = !DILocation(line: 8, column: 29, scope: !21, inlinedAt: !52)
!63 = !DILocation(line: 8, column: 23, scope: !21, inlinedAt: !52)
!64 = distinct !{!64, !55, !65, !40, !41}
!65 = !DILocation(line: 11, column: 5, scope: !18, inlinedAt: !52)
!66 = !DILocation(line: 12, column: 9, scope: !10, inlinedAt: !52)
!67 = !DILocation(line: 13, column: 16, scope: !10, inlinedAt: !52)
!68 = !DILocation(line: 13, column: 14, scope: !10, inlinedAt: !52)
!69 = !DILocation(line: 15, column: 18, scope: !50)
