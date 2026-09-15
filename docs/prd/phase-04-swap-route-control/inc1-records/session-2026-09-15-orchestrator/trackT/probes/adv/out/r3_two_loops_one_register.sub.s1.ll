; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r3_two_loops_one_register.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r3_two_loops_one_register.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !21
    #dbg_value(i32 %1, !15, !DIExpression(), !22)
    #dbg_value(i32 0, !16, !DIExpression(), !22)
    #dbg_value(i32 1, !17, !DIExpression(), !23)
  br label %2, !dbg !24

2:                                                ; preds = %0, %2
  %3 = phi i32 [ 1, %0 ], [ %9, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %8, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !23)
    #dbg_value(i32 %4, !16, !DIExpression(), !22)
  %5 = lshr i32 %1, %3, !dbg !25
  %6 = and i32 %5, 1, !dbg !25
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !25
  %8 = add nsw i32 %7, %4, !dbg !27
    #dbg_value(i32 %8, !16, !DIExpression(), !22)
  %9 = add nuw nsw i32 %3, 1, !dbg !28
    #dbg_value(i32 %9, !17, !DIExpression(), !23)
  %10 = icmp eq i32 %9, 3, !dbg !29
  br i1 %10, label %15, label %2, !dbg !24, !llvm.loop !30

11:                                               ; preds = %15
  %12 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !34
    #dbg_value(i32 %12, !15, !DIExpression(), !22)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !35
  %14 = add nsw i32 %13, %21, !dbg !36
  ret i32 %14, !dbg !37

15:                                               ; preds = %2, %15
  %16 = phi i32 [ %22, %15 ], [ 3, %2 ]
  %17 = phi i32 [ %21, %15 ], [ %8, %2 ]
    #dbg_value(i32 %16, !19, !DIExpression(), !38)
    #dbg_value(i32 %17, !16, !DIExpression(), !22)
  %18 = lshr i32 %1, %16, !dbg !39
  %19 = and i32 %18, 1, !dbg !39
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #2, !dbg !39
  %21 = add nsw i32 %20, %17, !dbg !41
    #dbg_value(i32 %21, !16, !DIExpression(), !22)
  %22 = add nuw nsw i32 %16, 1, !dbg !42
    #dbg_value(i32 %22, !19, !DIExpression(), !38)
  %23 = icmp eq i32 %22, 5, !dbg !43
  br i1 %23, label %11, label %15, !dbg !44, !llvm.loop !45
}

declare !dbg !47 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !52 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !55 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !56
    #dbg_value(i32 %1, !15, !DIExpression(), !58)
    #dbg_value(i32 0, !16, !DIExpression(), !58)
    #dbg_value(i32 1, !17, !DIExpression(), !59)
  br label %2, !dbg !60

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %9, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %8, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !59)
    #dbg_value(i32 %4, !16, !DIExpression(), !58)
  %5 = lshr i32 %1, %3, !dbg !61
  %6 = and i32 %5, 1, !dbg !61
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !61
  %8 = add nsw i32 %7, %4, !dbg !62
    #dbg_value(i32 %8, !16, !DIExpression(), !58)
  %9 = add nuw nsw i32 %3, 1, !dbg !63
    #dbg_value(i32 %9, !17, !DIExpression(), !59)
  %10 = icmp eq i32 %9, 3, !dbg !64
  br i1 %10, label %11, label %2, !dbg !60, !llvm.loop !65

11:                                               ; preds = %2, %11
  %12 = phi i32 [ %18, %11 ], [ 3, %2 ]
  %13 = phi i32 [ %17, %11 ], [ %8, %2 ]
    #dbg_value(i32 %12, !19, !DIExpression(), !67)
    #dbg_value(i32 %13, !16, !DIExpression(), !58)
  %14 = lshr i32 %1, %12, !dbg !68
  %15 = and i32 %14, 1, !dbg !68
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !68
  %17 = add nsw i32 %16, %13, !dbg !69
    #dbg_value(i32 %17, !16, !DIExpression(), !58)
  %18 = add nuw nsw i32 %12, 1, !dbg !70
    #dbg_value(i32 %18, !19, !DIExpression(), !67)
  %19 = icmp eq i32 %18, 5, !dbg !71
  br i1 %19, label %20, label %11, !dbg !72, !llvm.loop !73

20:                                               ; preds = %11
  %21 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !75
    #dbg_value(i32 %21, !15, !DIExpression(), !58)
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #2, !dbg !76
  %23 = add nsw i32 %22, %17, !dbg !77
  ret i32 %23, !dbg !78
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r3_two_loops_one_register.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "87e45a18d9733cfb8536352fce5222bc")
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
!19 = !DILocalVariable(name: "k", scope: !20, file: !8, line: 9, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!21 = !DILocation(line: 6, column: 13, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 0, scope: !18)
!24 = !DILocation(line: 8, column: 5, scope: !18)
!25 = !DILocation(line: 8, column: 39, scope: !26)
!26 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!27 = !DILocation(line: 8, column: 36, scope: !26)
!28 = !DILocation(line: 8, column: 29, scope: !26)
!29 = !DILocation(line: 8, column: 23, scope: !26)
!30 = distinct !{!30, !24, !31, !32, !33}
!31 = !DILocation(line: 8, column: 39, scope: !18)
!32 = !{!"llvm.loop.mustprogress"}
!33 = !{!"llvm.loop.unroll.disable"}
!34 = !DILocation(line: 10, column: 9, scope: !10)
!35 = !DILocation(line: 11, column: 16, scope: !10)
!36 = !DILocation(line: 11, column: 14, scope: !10)
!37 = !DILocation(line: 11, column: 5, scope: !10)
!38 = !DILocation(line: 0, scope: !20)
!39 = !DILocation(line: 9, column: 39, scope: !40)
!40 = distinct !DILexicalBlock(scope: !20, file: !8, line: 9, column: 5)
!41 = !DILocation(line: 9, column: 36, scope: !40)
!42 = !DILocation(line: 9, column: 29, scope: !40)
!43 = !DILocation(line: 9, column: 23, scope: !40)
!44 = !DILocation(line: 9, column: 5, scope: !20)
!45 = distinct !{!45, !44, !46, !32, !33}
!46 = !DILocation(line: 9, column: 39, scope: !20)
!47 = !DISubprogram(name: "cq_theta_si32", scope: !48, file: !48, line: 38, type: !49, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!48 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!49 = !DISubroutineType(types: !50)
!50 = !{!13, !13, !51}
!51 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!52 = !DISubprogram(name: "cq_measure_si32", scope: !48, file: !48, line: 83, type: !53, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!53 = !DISubroutineType(types: !54)
!54 = !{!13, !13}
!55 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!56 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !57)
!57 = distinct !DILocation(line: 13, column: 25, scope: !55)
!58 = !DILocation(line: 0, scope: !10, inlinedAt: !57)
!59 = !DILocation(line: 0, scope: !18, inlinedAt: !57)
!60 = !DILocation(line: 8, column: 5, scope: !18, inlinedAt: !57)
!61 = !DILocation(line: 8, column: 39, scope: !26, inlinedAt: !57)
!62 = !DILocation(line: 8, column: 36, scope: !26, inlinedAt: !57)
!63 = !DILocation(line: 8, column: 29, scope: !26, inlinedAt: !57)
!64 = !DILocation(line: 8, column: 23, scope: !26, inlinedAt: !57)
!65 = distinct !{!65, !60, !66, !32, !33}
!66 = !DILocation(line: 8, column: 39, scope: !18, inlinedAt: !57)
!67 = !DILocation(line: 0, scope: !20, inlinedAt: !57)
!68 = !DILocation(line: 9, column: 39, scope: !40, inlinedAt: !57)
!69 = !DILocation(line: 9, column: 36, scope: !40, inlinedAt: !57)
!70 = !DILocation(line: 9, column: 29, scope: !40, inlinedAt: !57)
!71 = !DILocation(line: 9, column: 23, scope: !40, inlinedAt: !57)
!72 = !DILocation(line: 9, column: 5, scope: !20, inlinedAt: !57)
!73 = distinct !{!73, !72, !74, !32, !33}
!74 = !DILocation(line: 9, column: 39, scope: !20, inlinedAt: !57)
!75 = !DILocation(line: 10, column: 9, scope: !10, inlinedAt: !57)
!76 = !DILocation(line: 11, column: 16, scope: !10, inlinedAt: !57)
!77 = !DILocation(line: 11, column: 14, scope: !10, inlinedAt: !57)
!78 = !DILocation(line: 13, column: 18, scope: !55)
