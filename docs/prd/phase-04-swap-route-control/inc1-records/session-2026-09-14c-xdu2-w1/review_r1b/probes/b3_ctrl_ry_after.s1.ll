; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b3_ctrl_ry_after.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b3_ctrl_ry_after.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !20
    #dbg_value(i32 %1, !15, !DIExpression(), !21)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !22
    #dbg_value(i32 %2, !16, !DIExpression(), !21)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
    #dbg_value(i32 1, !18, !DIExpression(), !23)
  br label %5, !dbg !24

3:                                                ; preds = %5
  %4 = icmp eq i32 %2, 0, !dbg !25
  br i1 %4, label %16, label %14, !dbg !27

5:                                                ; preds = %0, %5
  %6 = phi i32 [ 1, %0 ], [ %12, %5 ]
  %7 = phi i32 [ 0, %0 ], [ %11, %5 ]
    #dbg_value(i32 %6, !18, !DIExpression(), !23)
    #dbg_value(i32 %7, !17, !DIExpression(), !21)
  %8 = lshr i32 %1, %6, !dbg !28
  %9 = and i32 %8, 1, !dbg !28
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !28
  %11 = add nsw i32 %10, %7, !dbg !30
    #dbg_value(i32 %11, !17, !DIExpression(), !21)
  %12 = add nuw nsw i32 %6, 1, !dbg !31
    #dbg_value(i32 %12, !18, !DIExpression(), !23)
  %13 = icmp eq i32 %12, 3, !dbg !32
  br i1 %13, label %3, label %5, !dbg !24, !llvm.loop !33

14:                                               ; preds = %3
  %15 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !37
    #dbg_value(i32 %15, !15, !DIExpression(), !21)
  br label %16, !dbg !38

16:                                               ; preds = %14, %3
  %17 = phi i32 [ %15, %14 ], [ %1, %3 ], !dbg !21
    #dbg_value(i32 %17, !15, !DIExpression(), !21)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #2, !dbg !39
  %19 = add nsw i32 %18, %11, !dbg !40
  %20 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !41
  %21 = add nsw i32 %19, %20, !dbg !42
  ret i32 %21, !dbg !43
}

declare !dbg !44 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !49 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !52 {
  %1 = tail call i32 @slice(), !dbg !53
  ret i32 %1, !dbg !54
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b3_ctrl_ry_after.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "55c30448bc480d3d1f787e2edb9c4945")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 9, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 10, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 5)
!20 = !DILocation(line: 7, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 8, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !19)
!24 = !DILocation(line: 10, column: 5, scope: !19)
!25 = !DILocation(line: 12, column: 9, scope: !26)
!26 = distinct !DILexicalBlock(scope: !10, file: !8, line: 12, column: 9)
!27 = !DILocation(line: 12, column: 9, scope: !10)
!28 = !DILocation(line: 11, column: 14, scope: !29)
!29 = distinct !DILexicalBlock(scope: !19, file: !8, line: 10, column: 5)
!30 = !DILocation(line: 11, column: 11, scope: !29)
!31 = !DILocation(line: 10, column: 29, scope: !29)
!32 = !DILocation(line: 10, column: 23, scope: !29)
!33 = distinct !{!33, !24, !34, !35, !36}
!34 = !DILocation(line: 11, column: 14, scope: !19)
!35 = !{!"llvm.loop.mustprogress"}
!36 = !{!"llvm.loop.unroll.disable"}
!37 = !DILocation(line: 12, column: 16, scope: !26)
!38 = !DILocation(line: 12, column: 12, scope: !26)
!39 = !DILocation(line: 13, column: 16, scope: !10)
!40 = !DILocation(line: 13, column: 14, scope: !10)
!41 = !DILocation(line: 13, column: 32, scope: !10)
!42 = !DILocation(line: 13, column: 30, scope: !10)
!43 = !DILocation(line: 13, column: 5, scope: !10)
!44 = !DISubprogram(name: "cq_theta_si32", scope: !45, file: !45, line: 38, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!46 = !DISubroutineType(types: !47)
!47 = !{!13, !13, !48}
!48 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!49 = !DISubprogram(name: "cq_measure_si32", scope: !45, file: !45, line: 83, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!50 = !DISubroutineType(types: !51)
!51 = !{!13, !13}
!52 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!53 = !DILocation(line: 15, column: 25, scope: !52)
!54 = !DILocation(line: 15, column: 18, scope: !52)
