; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a3_mixed_invariant_rails.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a3_mixed_invariant_rails.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !20
    #dbg_value(i32 %1, !15, !DIExpression(), !21)
  %2 = mul nsw i32 %1, 3, !dbg !22
    #dbg_value(i32 %2, !16, !DIExpression(), !21)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
    #dbg_value(i32 1, !18, !DIExpression(), !23)
  %3 = and i32 %1, 1
    #dbg_value(i32 1, !18, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
  br label %8, !dbg !24

4:                                                ; preds = %8
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !25
    #dbg_value(i32 %5, !15, !DIExpression(), !21)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !26
  %7 = add nsw i32 %6, %16, !dbg !27
  ret i32 %7, !dbg !28

8:                                                ; preds = %0, %8
  %9 = phi i32 [ 1, %0 ], [ %17, %8 ]
  %10 = phi i32 [ 0, %0 ], [ %16, %8 ]
    #dbg_value(i32 %9, !18, !DIExpression(), !23)
    #dbg_value(i32 %10, !17, !DIExpression(), !21)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !29
  %12 = lshr i32 %2, %9, !dbg !31
  %13 = and i32 %12, 1, !dbg !31
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !31
  %15 = add i32 %11, %10, !dbg !32
  %16 = add i32 %15, %14, !dbg !33
    #dbg_value(i32 %16, !17, !DIExpression(), !21)
  %17 = add nuw nsw i32 %9, 1, !dbg !34
    #dbg_value(i32 %17, !18, !DIExpression(), !23)
  %18 = icmp eq i32 %17, 3, !dbg !35
  br i1 %18, label %4, label %8, !dbg !24, !llvm.loop !36
}

declare !dbg !40 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !45 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !48 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !49
    #dbg_value(i32 %1, !15, !DIExpression(), !51)
  %2 = mul nsw i32 %1, 3, !dbg !52
    #dbg_value(i32 %2, !16, !DIExpression(), !51)
    #dbg_value(i32 0, !17, !DIExpression(), !51)
    #dbg_value(i32 1, !18, !DIExpression(), !53)
  %3 = and i32 %1, 1
    #dbg_value(i32 1, !18, !DIExpression(), !53)
    #dbg_value(i32 0, !17, !DIExpression(), !51)
  br label %4, !dbg !54

4:                                                ; preds = %4, %0
  %5 = phi i32 [ 1, %0 ], [ %13, %4 ]
  %6 = phi i32 [ 0, %0 ], [ %12, %4 ]
    #dbg_value(i32 %5, !18, !DIExpression(), !53)
    #dbg_value(i32 %6, !17, !DIExpression(), !51)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !55
  %8 = lshr i32 %2, %5, !dbg !56
  %9 = and i32 %8, 1, !dbg !56
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !56
  %11 = add i32 %7, %6, !dbg !57
  %12 = add i32 %11, %10, !dbg !58
    #dbg_value(i32 %12, !17, !DIExpression(), !51)
  %13 = add nuw nsw i32 %5, 1, !dbg !59
    #dbg_value(i32 %13, !18, !DIExpression(), !53)
  %14 = icmp eq i32 %13, 3, !dbg !60
  br i1 %14, label %15, label %4, !dbg !54, !llvm.loop !61

15:                                               ; preds = %4
  %16 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !63
    #dbg_value(i32 %16, !15, !DIExpression(), !51)
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #2, !dbg !64
  %18 = add nsw i32 %17, %12, !dbg !65
  ret i32 %18, !dbg !66
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a3_mixed_invariant_rails.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "9add193e79401015542aae7560d6a49a")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "p", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 9, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 10, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 5)
!20 = !DILocation(line: 7, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 8, column: 15, scope: !10)
!23 = !DILocation(line: 0, scope: !19)
!24 = !DILocation(line: 10, column: 5, scope: !19)
!25 = !DILocation(line: 12, column: 9, scope: !10)
!26 = !DILocation(line: 13, column: 16, scope: !10)
!27 = !DILocation(line: 13, column: 14, scope: !10)
!28 = !DILocation(line: 13, column: 5, scope: !10)
!29 = !DILocation(line: 11, column: 14, scope: !30)
!30 = distinct !DILexicalBlock(scope: !19, file: !8, line: 10, column: 5)
!31 = !DILocation(line: 11, column: 34, scope: !30)
!32 = !DILocation(line: 11, column: 32, scope: !30)
!33 = !DILocation(line: 11, column: 11, scope: !30)
!34 = !DILocation(line: 10, column: 29, scope: !30)
!35 = !DILocation(line: 10, column: 23, scope: !30)
!36 = distinct !{!36, !24, !37, !38, !39}
!37 = !DILocation(line: 11, column: 34, scope: !19)
!38 = !{!"llvm.loop.mustprogress"}
!39 = !{!"llvm.loop.unroll.disable"}
!40 = !DISubprogram(name: "cq_theta_si32", scope: !41, file: !41, line: 38, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!42 = !DISubroutineType(types: !43)
!43 = !{!13, !13, !44}
!44 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!45 = !DISubprogram(name: "cq_measure_si32", scope: !41, file: !41, line: 83, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DISubroutineType(types: !47)
!47 = !{!13, !13}
!48 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!49 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !50)
!50 = distinct !DILocation(line: 15, column: 25, scope: !48)
!51 = !DILocation(line: 0, scope: !10, inlinedAt: !50)
!52 = !DILocation(line: 8, column: 15, scope: !10, inlinedAt: !50)
!53 = !DILocation(line: 0, scope: !19, inlinedAt: !50)
!54 = !DILocation(line: 10, column: 5, scope: !19, inlinedAt: !50)
!55 = !DILocation(line: 11, column: 14, scope: !30, inlinedAt: !50)
!56 = !DILocation(line: 11, column: 34, scope: !30, inlinedAt: !50)
!57 = !DILocation(line: 11, column: 32, scope: !30, inlinedAt: !50)
!58 = !DILocation(line: 11, column: 11, scope: !30, inlinedAt: !50)
!59 = !DILocation(line: 10, column: 29, scope: !30, inlinedAt: !50)
!60 = !DILocation(line: 10, column: 23, scope: !30, inlinedAt: !50)
!61 = distinct !{!61, !54, !62, !38, !39}
!62 = !DILocation(line: 11, column: 34, scope: !19, inlinedAt: !50)
!63 = !DILocation(line: 12, column: 9, scope: !10, inlinedAt: !50)
!64 = !DILocation(line: 13, column: 16, scope: !10, inlinedAt: !50)
!65 = !DILocation(line: 13, column: 14, scope: !10, inlinedAt: !50)
!66 = !DILocation(line: 15, column: 18, scope: !48)
