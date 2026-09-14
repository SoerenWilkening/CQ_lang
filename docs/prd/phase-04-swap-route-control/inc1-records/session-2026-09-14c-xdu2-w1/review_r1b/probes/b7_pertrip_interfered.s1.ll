; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b7_pertrip_interfered.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b7_pertrip_interfered.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !21)
    #dbg_value(i32 0, !16, !DIExpression(), !22)
  br label %2, !dbg !23

1:                                                ; preds = %2
  ret i32 %12, !dbg !24

2:                                                ; preds = %0, %2
  %3 = phi i32 [ 0, %0 ], [ %12, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %13, %2 ]
    #dbg_value(i32 %3, !15, !DIExpression(), !21)
    #dbg_value(i32 %4, !16, !DIExpression(), !22)
  %5 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !25
    #dbg_value(i32 %5, !18, !DIExpression(), !26)
  %6 = lshr i32 %5, 1, !dbg !27
  %7 = and i32 %6, 1, !dbg !27
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !27
  %9 = add nsw i32 %8, %3, !dbg !28
    #dbg_value(i32 %9, !15, !DIExpression(), !21)
  %10 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 9.000000e-01) #2, !dbg !29
    #dbg_value(i32 %10, !18, !DIExpression(), !26)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !30
  %12 = add nsw i32 %9, %11, !dbg !31
    #dbg_value(i32 %12, !15, !DIExpression(), !21)
  %13 = add nuw nsw i32 %4, 1, !dbg !32
    #dbg_value(i32 %13, !16, !DIExpression(), !22)
  %14 = icmp eq i32 %4, 0, !dbg !33
  br i1 %14, label %2, label %1, !dbg !23, !llvm.loop !34
}

declare !dbg !38 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !43 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !46 {
    #dbg_value(i32 0, !15, !DIExpression(), !47)
    #dbg_value(i32 0, !16, !DIExpression(), !49)
  br label %1, !dbg !50

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %11, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %12, %1 ]
    #dbg_value(i32 %2, !15, !DIExpression(), !47)
    #dbg_value(i32 %3, !16, !DIExpression(), !49)
  %4 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !51
    #dbg_value(i32 %4, !18, !DIExpression(), !52)
  %5 = lshr i32 %4, 1, !dbg !53
  %6 = and i32 %5, 1, !dbg !53
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !53
  %8 = add nsw i32 %7, %2, !dbg !54
    #dbg_value(i32 %8, !15, !DIExpression(), !47)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 9.000000e-01) #2, !dbg !55
    #dbg_value(i32 %9, !18, !DIExpression(), !52)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !56
  %11 = add nsw i32 %8, %10, !dbg !57
    #dbg_value(i32 %11, !15, !DIExpression(), !47)
  %12 = add nuw nsw i32 %3, 1, !dbg !58
    #dbg_value(i32 %12, !16, !DIExpression(), !49)
  %13 = icmp eq i32 %3, 0, !dbg !59
  br i1 %13, label %1, label %14, !dbg !50, !llvm.loop !60

14:                                               ; preds = %1
  ret i32 %11, !dbg !62
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b7_pertrip_interfered.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "a0616bca94e8b485b9a9276ad1bf99e0")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 7, type: !11, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18}
!15 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!16 = !DILocalVariable(name: "k", scope: !17, file: !8, line: 9, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!18 = !DILocalVariable(name: "u", scope: !19, file: !8, line: 10, type: !13)
!19 = distinct !DILexicalBlock(scope: !20, file: !8, line: 9, column: 33)
!20 = distinct !DILexicalBlock(scope: !17, file: !8, line: 9, column: 5)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 0, scope: !17)
!23 = !DILocation(line: 9, column: 5, scope: !17)
!24 = !DILocation(line: 15, column: 5, scope: !10)
!25 = !DILocation(line: 10, column: 17, scope: !19)
!26 = !DILocation(line: 0, scope: !19)
!27 = !DILocation(line: 11, column: 14, scope: !19)
!28 = !DILocation(line: 11, column: 11, scope: !19)
!29 = !DILocation(line: 12, column: 13, scope: !19)
!30 = !DILocation(line: 13, column: 14, scope: !19)
!31 = !DILocation(line: 13, column: 11, scope: !19)
!32 = !DILocation(line: 9, column: 28, scope: !20)
!33 = !DILocation(line: 9, column: 23, scope: !20)
!34 = distinct !{!34, !23, !35, !36, !37}
!35 = !DILocation(line: 14, column: 5, scope: !17)
!36 = !{!"llvm.loop.mustprogress"}
!37 = !{!"llvm.loop.unroll.disable"}
!38 = !DISubprogram(name: "cq_theta_si32", scope: !39, file: !39, line: 38, type: !40, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!39 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!40 = !DISubroutineType(types: !41)
!41 = !{!13, !13, !42}
!42 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!43 = !DISubprogram(name: "cq_measure_si32", scope: !39, file: !39, line: 83, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DISubroutineType(types: !45)
!45 = !{!13, !13}
!46 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 17, type: !11, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!47 = !DILocation(line: 0, scope: !10, inlinedAt: !48)
!48 = distinct !DILocation(line: 17, column: 25, scope: !46)
!49 = !DILocation(line: 0, scope: !17, inlinedAt: !48)
!50 = !DILocation(line: 9, column: 5, scope: !17, inlinedAt: !48)
!51 = !DILocation(line: 10, column: 17, scope: !19, inlinedAt: !48)
!52 = !DILocation(line: 0, scope: !19, inlinedAt: !48)
!53 = !DILocation(line: 11, column: 14, scope: !19, inlinedAt: !48)
!54 = !DILocation(line: 11, column: 11, scope: !19, inlinedAt: !48)
!55 = !DILocation(line: 12, column: 13, scope: !19, inlinedAt: !48)
!56 = !DILocation(line: 13, column: 14, scope: !19, inlinedAt: !48)
!57 = !DILocation(line: 13, column: 11, scope: !19, inlinedAt: !48)
!58 = !DILocation(line: 9, column: 28, scope: !20, inlinedAt: !48)
!59 = !DILocation(line: 9, column: 23, scope: !20, inlinedAt: !48)
!60 = distinct !{!60, !50, !61, !36, !37}
!61 = !DILocation(line: 14, column: 5, scope: !17, inlinedAt: !48)
!62 = !DILocation(line: 17, column: 18, scope: !46)
