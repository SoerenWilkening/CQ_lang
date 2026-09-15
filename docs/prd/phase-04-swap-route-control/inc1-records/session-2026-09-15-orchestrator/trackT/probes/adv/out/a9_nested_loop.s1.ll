; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a9_nested_loop.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a9_nested_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i32 %1, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 1, !17, !DIExpression(), !24)
  br label %2, !dbg !25

2:                                                ; preds = %0, %9
  %3 = phi i32 [ 1, %0 ], [ %10, %9 ]
  %4 = phi i32 [ 0, %0 ], [ %19, %9 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !24)
    #dbg_value(i32 %4, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !19, !DIExpression(), !26)
    #dbg_value(i32 %4, !16, !DIExpression(), !23)
  br label %12, !dbg !27

5:                                                ; preds = %9
  %6 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !28
    #dbg_value(i32 %6, !15, !DIExpression(), !23)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !29
  %8 = add nsw i32 %7, %19, !dbg !30
  ret i32 %8, !dbg !31

9:                                                ; preds = %12
  %10 = add nuw nsw i32 %3, 1, !dbg !32
    #dbg_value(i32 %10, !17, !DIExpression(), !24)
    #dbg_value(i32 %19, !16, !DIExpression(), !23)
  %11 = icmp eq i32 %10, 3, !dbg !33
  br i1 %11, label %5, label %2, !dbg !25, !llvm.loop !34

12:                                               ; preds = %2, %12
  %13 = phi i32 [ 0, %2 ], [ %20, %12 ]
  %14 = phi i32 [ %4, %2 ], [ %19, %12 ]
    #dbg_value(i32 %13, !19, !DIExpression(), !26)
    #dbg_value(i32 %14, !16, !DIExpression(), !23)
  %15 = add nuw nsw i32 %13, %3, !dbg !38
  %16 = lshr i32 %1, %15, !dbg !38
  %17 = and i32 %16, 1, !dbg !38
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #2, !dbg !38
  %19 = add nsw i32 %18, %14, !dbg !40
    #dbg_value(i32 %19, !16, !DIExpression(), !23)
  %20 = add nuw nsw i32 %13, 1, !dbg !41
    #dbg_value(i32 %20, !19, !DIExpression(), !26)
  %21 = icmp eq i32 %13, 0, !dbg !42
  br i1 %21, label %12, label %9, !dbg !27, !llvm.loop !43
}

declare !dbg !45 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !50 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !53 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !54
    #dbg_value(i32 %1, !15, !DIExpression(), !56)
    #dbg_value(i32 0, !16, !DIExpression(), !56)
    #dbg_value(i32 1, !17, !DIExpression(), !57)
  br label %2, !dbg !58

2:                                                ; preds = %5, %0
  %3 = phi i32 [ 1, %0 ], [ %6, %5 ]
  %4 = phi i32 [ 0, %0 ], [ %15, %5 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !57)
    #dbg_value(i32 %4, !16, !DIExpression(), !56)
    #dbg_value(i32 0, !19, !DIExpression(), !59)
    #dbg_value(i32 %4, !16, !DIExpression(), !56)
  br label %8, !dbg !60

5:                                                ; preds = %8
  %6 = add nuw nsw i32 %3, 1, !dbg !61
    #dbg_value(i32 %6, !17, !DIExpression(), !57)
    #dbg_value(i32 %15, !16, !DIExpression(), !56)
  %7 = icmp eq i32 %6, 3, !dbg !62
  br i1 %7, label %18, label %2, !dbg !58, !llvm.loop !63

8:                                                ; preds = %8, %2
  %9 = phi i32 [ 0, %2 ], [ %16, %8 ]
  %10 = phi i32 [ %4, %2 ], [ %15, %8 ]
    #dbg_value(i32 %9, !19, !DIExpression(), !59)
    #dbg_value(i32 %10, !16, !DIExpression(), !56)
  %11 = add nuw nsw i32 %9, %3, !dbg !65
  %12 = lshr i32 %1, %11, !dbg !65
  %13 = and i32 %12, 1, !dbg !65
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !65
  %15 = add nsw i32 %14, %10, !dbg !66
    #dbg_value(i32 %15, !16, !DIExpression(), !56)
  %16 = add nuw nsw i32 %9, 1, !dbg !67
    #dbg_value(i32 %16, !19, !DIExpression(), !59)
  %17 = icmp eq i32 %9, 0, !dbg !68
  br i1 %17, label %8, label %5, !dbg !60, !llvm.loop !69

18:                                               ; preds = %5
  %19 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !71
    #dbg_value(i32 %19, !15, !DIExpression(), !56)
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #2, !dbg !72
  %21 = add nsw i32 %20, %15, !dbg !73
  ret i32 %21, !dbg !74
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a9_nested_loop.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "bc2733bb572ff19a55579408637c1274")
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
!19 = !DILocalVariable(name: "j", scope: !20, file: !8, line: 9, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 9, column: 9)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!22 = !DILocation(line: 6, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 8, column: 5, scope: !18)
!26 = !DILocation(line: 0, scope: !20)
!27 = !DILocation(line: 9, column: 9, scope: !20)
!28 = !DILocation(line: 11, column: 9, scope: !10)
!29 = !DILocation(line: 12, column: 16, scope: !10)
!30 = !DILocation(line: 12, column: 14, scope: !10)
!31 = !DILocation(line: 12, column: 5, scope: !10)
!32 = !DILocation(line: 8, column: 29, scope: !21)
!33 = !DILocation(line: 8, column: 23, scope: !21)
!34 = distinct !{!34, !25, !35, !36, !37}
!35 = !DILocation(line: 10, column: 18, scope: !18)
!36 = !{!"llvm.loop.mustprogress"}
!37 = !{!"llvm.loop.unroll.disable"}
!38 = !DILocation(line: 10, column: 18, scope: !39)
!39 = distinct !DILexicalBlock(scope: !20, file: !8, line: 9, column: 9)
!40 = !DILocation(line: 10, column: 15, scope: !39)
!41 = !DILocation(line: 9, column: 32, scope: !39)
!42 = !DILocation(line: 9, column: 27, scope: !39)
!43 = distinct !{!43, !27, !44, !36, !37}
!44 = !DILocation(line: 10, column: 18, scope: !20)
!45 = !DISubprogram(name: "cq_theta_si32", scope: !46, file: !46, line: 38, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!47 = !DISubroutineType(types: !48)
!48 = !{!13, !13, !49}
!49 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!50 = !DISubprogram(name: "cq_measure_si32", scope: !46, file: !46, line: 83, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DISubroutineType(types: !52)
!52 = !{!13, !13}
!53 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 14, type: !11, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!54 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !55)
!55 = distinct !DILocation(line: 14, column: 25, scope: !53)
!56 = !DILocation(line: 0, scope: !10, inlinedAt: !55)
!57 = !DILocation(line: 0, scope: !18, inlinedAt: !55)
!58 = !DILocation(line: 8, column: 5, scope: !18, inlinedAt: !55)
!59 = !DILocation(line: 0, scope: !20, inlinedAt: !55)
!60 = !DILocation(line: 9, column: 9, scope: !20, inlinedAt: !55)
!61 = !DILocation(line: 8, column: 29, scope: !21, inlinedAt: !55)
!62 = !DILocation(line: 8, column: 23, scope: !21, inlinedAt: !55)
!63 = distinct !{!63, !58, !64, !36, !37}
!64 = !DILocation(line: 10, column: 18, scope: !18, inlinedAt: !55)
!65 = !DILocation(line: 10, column: 18, scope: !39, inlinedAt: !55)
!66 = !DILocation(line: 10, column: 15, scope: !39, inlinedAt: !55)
!67 = !DILocation(line: 9, column: 32, scope: !39, inlinedAt: !55)
!68 = !DILocation(line: 9, column: 27, scope: !39, inlinedAt: !55)
!69 = distinct !{!69, !60, !70, !36, !37}
!70 = !DILocation(line: 10, column: 18, scope: !20, inlinedAt: !55)
!71 = !DILocation(line: 11, column: 9, scope: !10, inlinedAt: !55)
!72 = !DILocation(line: 12, column: 16, scope: !10, inlinedAt: !55)
!73 = !DILocation(line: 12, column: 14, scope: !10, inlinedAt: !55)
!74 = !DILocation(line: 14, column: 18, scope: !53)
