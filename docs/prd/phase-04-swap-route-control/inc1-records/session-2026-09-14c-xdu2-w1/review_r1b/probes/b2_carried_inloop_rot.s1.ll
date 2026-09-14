; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b2_carried_inloop_rot.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b2_carried_inloop_rot.c"
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
  %3 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !23
  %4 = add nsw i32 %3, %12, !dbg !24
  ret i32 %4, !dbg !25

5:                                                ; preds = %0, %5
  %6 = phi i32 [ 1, %0 ], [ %14, %5 ]
  %7 = phi i32 [ 0, %0 ], [ %12, %5 ]
  %8 = phi i32 [ %1, %0 ], [ %13, %5 ]
    #dbg_value(i32 %6, !17, !DIExpression(), !21)
    #dbg_value(i32 %7, !16, !DIExpression(), !20)
    #dbg_value(i32 %8, !15, !DIExpression(), !20)
  %9 = lshr i32 %8, %6, !dbg !26
  %10 = and i32 %9, 1, !dbg !26
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !26
  %12 = add nsw i32 %11, %7, !dbg !29
    #dbg_value(i32 %12, !16, !DIExpression(), !20)
  %13 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 1.000000e-01) #2, !dbg !30
    #dbg_value(i32 %13, !15, !DIExpression(), !20)
  %14 = add nuw nsw i32 %6, 1, !dbg !31
    #dbg_value(i32 %14, !17, !DIExpression(), !21)
  %15 = icmp eq i32 %14, 3, !dbg !32
  br i1 %15, label %2, label %5, !dbg !22, !llvm.loop !33
}

declare !dbg !37 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !42 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !45 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !46
    #dbg_value(i32 %1, !15, !DIExpression(), !48)
    #dbg_value(i32 0, !16, !DIExpression(), !48)
    #dbg_value(i32 1, !17, !DIExpression(), !49)
  br label %2, !dbg !50

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %11, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %9, %2 ]
  %5 = phi i32 [ %1, %0 ], [ %10, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !49)
    #dbg_value(i32 %4, !16, !DIExpression(), !48)
    #dbg_value(i32 %5, !15, !DIExpression(), !48)
  %6 = lshr i32 %5, %3, !dbg !51
  %7 = and i32 %6, 1, !dbg !51
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !51
  %9 = add nsw i32 %8, %4, !dbg !52
    #dbg_value(i32 %9, !16, !DIExpression(), !48)
  %10 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 1.000000e-01) #2, !dbg !53
    #dbg_value(i32 %10, !15, !DIExpression(), !48)
  %11 = add nuw nsw i32 %3, 1, !dbg !54
    #dbg_value(i32 %11, !17, !DIExpression(), !49)
  %12 = icmp eq i32 %11, 3, !dbg !55
  br i1 %12, label %13, label %2, !dbg !50, !llvm.loop !56

13:                                               ; preds = %2
  %14 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !58
  %15 = add nsw i32 %14, %9, !dbg !59
  ret i32 %15, !dbg !60
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b2_carried_inloop_rot.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "010b28f789282f11d19df014ad8512f4")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 8, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!19 = !DILocation(line: 6, column: 13, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 8, column: 5, scope: !18)
!23 = !DILocation(line: 12, column: 16, scope: !10)
!24 = !DILocation(line: 12, column: 14, scope: !10)
!25 = !DILocation(line: 12, column: 5, scope: !10)
!26 = !DILocation(line: 9, column: 14, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !8, line: 8, column: 34)
!28 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!29 = !DILocation(line: 9, column: 11, scope: !27)
!30 = !DILocation(line: 10, column: 13, scope: !27)
!31 = !DILocation(line: 8, column: 29, scope: !28)
!32 = !DILocation(line: 8, column: 23, scope: !28)
!33 = distinct !{!33, !22, !34, !35, !36}
!34 = !DILocation(line: 11, column: 5, scope: !18)
!35 = !{!"llvm.loop.mustprogress"}
!36 = !{!"llvm.loop.unroll.disable"}
!37 = !DISubprogram(name: "cq_theta_si32", scope: !38, file: !38, line: 38, type: !39, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!39 = !DISubroutineType(types: !40)
!40 = !{!13, !13, !41}
!41 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!42 = !DISubprogram(name: "cq_measure_si32", scope: !38, file: !38, line: 83, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DISubroutineType(types: !44)
!44 = !{!13, !13}
!45 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 14, type: !11, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!46 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !47)
!47 = distinct !DILocation(line: 14, column: 25, scope: !45)
!48 = !DILocation(line: 0, scope: !10, inlinedAt: !47)
!49 = !DILocation(line: 0, scope: !18, inlinedAt: !47)
!50 = !DILocation(line: 8, column: 5, scope: !18, inlinedAt: !47)
!51 = !DILocation(line: 9, column: 14, scope: !27, inlinedAt: !47)
!52 = !DILocation(line: 9, column: 11, scope: !27, inlinedAt: !47)
!53 = !DILocation(line: 10, column: 13, scope: !27, inlinedAt: !47)
!54 = !DILocation(line: 8, column: 29, scope: !28, inlinedAt: !47)
!55 = !DILocation(line: 8, column: 23, scope: !28, inlinedAt: !47)
!56 = distinct !{!56, !50, !57, !35, !36}
!57 = !DILocation(line: 11, column: 5, scope: !18, inlinedAt: !47)
!58 = !DILocation(line: 12, column: 16, scope: !10, inlinedAt: !47)
!59 = !DILocation(line: 12, column: 14, scope: !10, inlinedAt: !47)
!60 = !DILocation(line: 14, column: 18, scope: !45)
