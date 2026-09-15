; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t2_nonlive_shift.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t2_nonlive_shift.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !19
    #dbg_value(i32 %1, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 1, !17, !DIExpression(), !21)
  br label %5, !dbg !22

2:                                                ; preds = %5
  %3 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !23
  %4 = add nsw i32 %3, %11, !dbg !24
  ret i32 %4, !dbg !25

5:                                                ; preds = %0, %5
  %6 = phi i32 [ 1, %0 ], [ %12, %5 ]
  %7 = phi i32 [ 0, %0 ], [ %11, %5 ]
    #dbg_value(i32 %6, !17, !DIExpression(), !21)
    #dbg_value(i32 %7, !16, !DIExpression(), !20)
  %8 = lshr i32 %1, %6, !dbg !26
  %9 = and i32 %8, 1, !dbg !26
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !26
  %11 = add nsw i32 %10, %7, !dbg !28
    #dbg_value(i32 %11, !16, !DIExpression(), !20)
  %12 = add nuw nsw i32 %6, 1, !dbg !29
    #dbg_value(i32 %12, !17, !DIExpression(), !21)
  %13 = icmp eq i32 %12, 3, !dbg !30
  br i1 %13, label %2, label %5, !dbg !22, !llvm.loop !31
}

declare !dbg !35 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !40 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !43 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !44
    #dbg_value(i32 %1, !15, !DIExpression(), !46)
    #dbg_value(i32 0, !16, !DIExpression(), !46)
    #dbg_value(i32 1, !17, !DIExpression(), !47)
  br label %2, !dbg !48

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %9, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %8, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !47)
    #dbg_value(i32 %4, !16, !DIExpression(), !46)
  %5 = lshr i32 %1, %3, !dbg !49
  %6 = and i32 %5, 1, !dbg !49
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !49
  %8 = add nsw i32 %7, %4, !dbg !50
    #dbg_value(i32 %8, !16, !DIExpression(), !46)
  %9 = add nuw nsw i32 %3, 1, !dbg !51
    #dbg_value(i32 %9, !17, !DIExpression(), !47)
  %10 = icmp eq i32 %9, 3, !dbg !52
  br i1 %10, label %11, label %2, !dbg !48, !llvm.loop !53

11:                                               ; preds = %2
  %12 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !55
  %13 = add nsw i32 %12, %8, !dbg !56
  ret i32 %13, !dbg !57
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t2_nonlive_shift.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "62b54c2045e5eb67419694803af2155d")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
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
!23 = !DILocation(line: 11, column: 16, scope: !10)
!24 = !DILocation(line: 11, column: 14, scope: !10)
!25 = !DILocation(line: 11, column: 5, scope: !10)
!26 = !DILocation(line: 10, column: 14, scope: !27)
!27 = distinct !DILexicalBlock(scope: !18, file: !8, line: 9, column: 5)
!28 = !DILocation(line: 10, column: 11, scope: !27)
!29 = !DILocation(line: 9, column: 29, scope: !27)
!30 = !DILocation(line: 9, column: 23, scope: !27)
!31 = distinct !{!31, !22, !32, !33, !34}
!32 = !DILocation(line: 10, column: 14, scope: !18)
!33 = !{!"llvm.loop.mustprogress"}
!34 = !{!"llvm.loop.unroll.disable"}
!35 = !DISubprogram(name: "cq_theta_si32", scope: !36, file: !36, line: 38, type: !37, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!36 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!37 = !DISubroutineType(types: !38)
!38 = !{!13, !13, !39}
!39 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!40 = !DISubprogram(name: "cq_measure_si32", scope: !36, file: !36, line: 83, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DISubroutineType(types: !42)
!42 = !{!13, !13}
!43 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!44 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !45)
!45 = distinct !DILocation(line: 13, column: 25, scope: !43)
!46 = !DILocation(line: 0, scope: !10, inlinedAt: !45)
!47 = !DILocation(line: 0, scope: !18, inlinedAt: !45)
!48 = !DILocation(line: 9, column: 5, scope: !18, inlinedAt: !45)
!49 = !DILocation(line: 10, column: 14, scope: !27, inlinedAt: !45)
!50 = !DILocation(line: 10, column: 11, scope: !27, inlinedAt: !45)
!51 = !DILocation(line: 9, column: 29, scope: !27, inlinedAt: !45)
!52 = !DILocation(line: 9, column: 23, scope: !27, inlinedAt: !45)
!53 = distinct !{!53, !48, !54, !33, !34}
!54 = !DILocation(line: 10, column: 14, scope: !18, inlinedAt: !45)
!55 = !DILocation(line: 11, column: 16, scope: !10, inlinedAt: !45)
!56 = !DILocation(line: 11, column: 14, scope: !10, inlinedAt: !45)
!57 = !DILocation(line: 13, column: 18, scope: !43)
