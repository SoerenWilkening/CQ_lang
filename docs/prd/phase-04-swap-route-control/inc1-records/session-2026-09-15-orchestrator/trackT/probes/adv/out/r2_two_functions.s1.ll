; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r2_two_functions.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r2_two_functions.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ka() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !19
    #dbg_value(i32 %1, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 1, !17, !DIExpression(), !21)
  br label %6, !dbg !22

2:                                                ; preds = %6
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !23
    #dbg_value(i32 %3, !15, !DIExpression(), !20)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !24
  %5 = add nsw i32 %4, %12, !dbg !25
  ret i32 %5, !dbg !26

6:                                                ; preds = %0, %6
  %7 = phi i32 [ 1, %0 ], [ %13, %6 ]
  %8 = phi i32 [ 0, %0 ], [ %12, %6 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !21)
    #dbg_value(i32 %8, !16, !DIExpression(), !20)
  %9 = lshr i32 %1, %7, !dbg !27
  %10 = and i32 %9, 1, !dbg !27
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !27
  %12 = add nsw i32 %11, %8, !dbg !29
    #dbg_value(i32 %12, !16, !DIExpression(), !20)
  %13 = add nuw nsw i32 %7, 1, !dbg !30
    #dbg_value(i32 %13, !17, !DIExpression(), !21)
  %14 = icmp eq i32 %13, 3, !dbg !31
  br i1 %14, label %2, label %6, !dbg !22, !llvm.loop !32
}

declare !dbg !36 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !41 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @kb() local_unnamed_addr #0 !dbg !44 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !51
    #dbg_value(i32 %1, !46, !DIExpression(), !52)
  %2 = mul nsw i32 %1, 3, !dbg !53
    #dbg_value(i32 %2, !47, !DIExpression(), !52)
    #dbg_value(i32 0, !48, !DIExpression(), !52)
    #dbg_value(i32 1, !49, !DIExpression(), !54)
  br label %6, !dbg !55

3:                                                ; preds = %6
  %4 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !56
  %5 = add nsw i32 %4, %12, !dbg !57
  ret i32 %5, !dbg !58

6:                                                ; preds = %0, %6
  %7 = phi i32 [ 1, %0 ], [ %13, %6 ]
  %8 = phi i32 [ 0, %0 ], [ %12, %6 ]
    #dbg_value(i32 %7, !49, !DIExpression(), !54)
    #dbg_value(i32 %8, !48, !DIExpression(), !52)
  %9 = lshr i32 %2, %7, !dbg !59
  %10 = and i32 %9, 1, !dbg !59
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !59
  %12 = add nsw i32 %11, %8, !dbg !61
    #dbg_value(i32 %12, !48, !DIExpression(), !52)
  %13 = add nuw nsw i32 %7, 1, !dbg !62
    #dbg_value(i32 %13, !49, !DIExpression(), !54)
  %14 = icmp eq i32 %13, 3, !dbg !63
  br i1 %14, label %3, label %6, !dbg !55, !llvm.loop !64
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !66 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !67
    #dbg_value(i32 %1, !15, !DIExpression(), !69)
    #dbg_value(i32 0, !16, !DIExpression(), !69)
    #dbg_value(i32 1, !17, !DIExpression(), !70)
  br label %2, !dbg !71

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %9, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %8, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !70)
    #dbg_value(i32 %4, !16, !DIExpression(), !69)
  %5 = lshr i32 %1, %3, !dbg !72
  %6 = and i32 %5, 1, !dbg !72
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !72
  %8 = add nsw i32 %7, %4, !dbg !73
    #dbg_value(i32 %8, !16, !DIExpression(), !69)
  %9 = add nuw nsw i32 %3, 1, !dbg !74
    #dbg_value(i32 %9, !17, !DIExpression(), !70)
  %10 = icmp eq i32 %9, 3, !dbg !75
  br i1 %10, label %11, label %2, !dbg !71, !llvm.loop !76

11:                                               ; preds = %2
  %12 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !78
    #dbg_value(i32 %12, !15, !DIExpression(), !69)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !79
  %14 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !80
    #dbg_value(i32 %14, !46, !DIExpression(), !82)
  %15 = mul nsw i32 %14, 3, !dbg !83
    #dbg_value(i32 %15, !47, !DIExpression(), !82)
    #dbg_value(i32 0, !48, !DIExpression(), !82)
    #dbg_value(i32 1, !49, !DIExpression(), !84)
  br label %16, !dbg !85

16:                                               ; preds = %16, %11
  %17 = phi i32 [ 1, %11 ], [ %23, %16 ]
  %18 = phi i32 [ 0, %11 ], [ %22, %16 ]
    #dbg_value(i32 %17, !49, !DIExpression(), !84)
    #dbg_value(i32 %18, !48, !DIExpression(), !82)
  %19 = lshr i32 %15, %17, !dbg !86
  %20 = and i32 %19, 1, !dbg !86
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #2, !dbg !86
  %22 = add nsw i32 %21, %18, !dbg !87
    #dbg_value(i32 %22, !48, !DIExpression(), !82)
  %23 = add nuw nsw i32 %17, 1, !dbg !88
    #dbg_value(i32 %23, !49, !DIExpression(), !84)
  %24 = icmp eq i32 %23, 3, !dbg !89
  br i1 %24, label %25, label %16, !dbg !85, !llvm.loop !90

25:                                               ; preds = %16
  %26 = tail call i32 @cq_measure_si32(i32 noundef %14) #2, !dbg !92
  %27 = add i32 %13, %8, !dbg !93
  %28 = add i32 %27, %22, !dbg !94
  %29 = add i32 %28, %26, !dbg !95
  ret i32 %29, !dbg !96
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r2_two_functions.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "1453bf4233c4e8c9750fd80566a77641")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "ka", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 9, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!19 = !DILocation(line: 7, column: 13, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 9, column: 5, scope: !18)
!23 = !DILocation(line: 10, column: 9, scope: !10)
!24 = !DILocation(line: 11, column: 16, scope: !10)
!25 = !DILocation(line: 11, column: 14, scope: !10)
!26 = !DILocation(line: 11, column: 5, scope: !10)
!27 = !DILocation(line: 9, column: 39, scope: !28)
!28 = distinct !DILexicalBlock(scope: !18, file: !8, line: 9, column: 5)
!29 = !DILocation(line: 9, column: 36, scope: !28)
!30 = !DILocation(line: 9, column: 29, scope: !28)
!31 = !DILocation(line: 9, column: 23, scope: !28)
!32 = distinct !{!32, !22, !33, !34, !35}
!33 = !DILocation(line: 9, column: 39, scope: !18)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.unroll.disable"}
!36 = !DISubprogram(name: "cq_theta_si32", scope: !37, file: !37, line: 38, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!38 = !DISubroutineType(types: !39)
!39 = !{!13, !13, !40}
!40 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!41 = !DISubprogram(name: "cq_measure_si32", scope: !37, file: !37, line: 83, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DISubroutineType(types: !43)
!43 = !{!13, !13}
!44 = distinct !DISubprogram(name: "kb", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !45)
!45 = !{!46, !47, !48, !49}
!46 = !DILocalVariable(name: "y", scope: !44, file: !8, line: 14, type: !13)
!47 = !DILocalVariable(name: "p", scope: !44, file: !8, line: 15, type: !13)
!48 = !DILocalVariable(name: "s", scope: !44, file: !8, line: 16, type: !13)
!49 = !DILocalVariable(name: "k", scope: !50, file: !8, line: 17, type: !13)
!50 = distinct !DILexicalBlock(scope: !44, file: !8, line: 17, column: 5)
!51 = !DILocation(line: 14, column: 13, scope: !44)
!52 = !DILocation(line: 0, scope: !44)
!53 = !DILocation(line: 15, column: 15, scope: !44)
!54 = !DILocation(line: 0, scope: !50)
!55 = !DILocation(line: 17, column: 5, scope: !50)
!56 = !DILocation(line: 18, column: 16, scope: !44)
!57 = !DILocation(line: 18, column: 14, scope: !44)
!58 = !DILocation(line: 18, column: 5, scope: !44)
!59 = !DILocation(line: 17, column: 39, scope: !60)
!60 = distinct !DILexicalBlock(scope: !50, file: !8, line: 17, column: 5)
!61 = !DILocation(line: 17, column: 36, scope: !60)
!62 = !DILocation(line: 17, column: 29, scope: !60)
!63 = !DILocation(line: 17, column: 23, scope: !60)
!64 = distinct !{!64, !55, !65, !34, !35}
!65 = !DILocation(line: 17, column: 39, scope: !50)
!66 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 20, type: !11, scopeLine: 20, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!67 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !68)
!68 = distinct !DILocation(line: 20, column: 25, scope: !66)
!69 = !DILocation(line: 0, scope: !10, inlinedAt: !68)
!70 = !DILocation(line: 0, scope: !18, inlinedAt: !68)
!71 = !DILocation(line: 9, column: 5, scope: !18, inlinedAt: !68)
!72 = !DILocation(line: 9, column: 39, scope: !28, inlinedAt: !68)
!73 = !DILocation(line: 9, column: 36, scope: !28, inlinedAt: !68)
!74 = !DILocation(line: 9, column: 29, scope: !28, inlinedAt: !68)
!75 = !DILocation(line: 9, column: 23, scope: !28, inlinedAt: !68)
!76 = distinct !{!76, !71, !77, !34, !35}
!77 = !DILocation(line: 9, column: 39, scope: !18, inlinedAt: !68)
!78 = !DILocation(line: 10, column: 9, scope: !10, inlinedAt: !68)
!79 = !DILocation(line: 11, column: 16, scope: !10, inlinedAt: !68)
!80 = !DILocation(line: 14, column: 13, scope: !44, inlinedAt: !81)
!81 = distinct !DILocation(line: 20, column: 32, scope: !66)
!82 = !DILocation(line: 0, scope: !44, inlinedAt: !81)
!83 = !DILocation(line: 15, column: 15, scope: !44, inlinedAt: !81)
!84 = !DILocation(line: 0, scope: !50, inlinedAt: !81)
!85 = !DILocation(line: 17, column: 5, scope: !50, inlinedAt: !81)
!86 = !DILocation(line: 17, column: 39, scope: !60, inlinedAt: !81)
!87 = !DILocation(line: 17, column: 36, scope: !60, inlinedAt: !81)
!88 = !DILocation(line: 17, column: 29, scope: !60, inlinedAt: !81)
!89 = !DILocation(line: 17, column: 23, scope: !60, inlinedAt: !81)
!90 = distinct !{!90, !85, !91, !34, !35}
!91 = !DILocation(line: 17, column: 39, scope: !50, inlinedAt: !81)
!92 = !DILocation(line: 18, column: 16, scope: !44, inlinedAt: !81)
!93 = !DILocation(line: 18, column: 14, scope: !44, inlinedAt: !81)
!94 = !DILocation(line: 11, column: 14, scope: !10, inlinedAt: !68)
!95 = !DILocation(line: 20, column: 30, scope: !66)
!96 = !DILocation(line: 20, column: 18, scope: !66)
