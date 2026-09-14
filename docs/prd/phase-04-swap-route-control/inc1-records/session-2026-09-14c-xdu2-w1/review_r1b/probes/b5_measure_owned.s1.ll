; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b5_measure_owned.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b5_measure_owned.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !19
    #dbg_value(i32 %1, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 1, !17, !DIExpression(), !21)
  br label %6, !dbg !22

2:                                                ; preds = %6
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !23
    #dbg_value(i32 %3, !15, !DIExpression(), !20)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !24
  %5 = add nsw i32 %4, %11, !dbg !25
  ret i32 %5, !dbg !26

6:                                                ; preds = %0, %6
  %7 = phi i32 [ 1, %0 ], [ %12, %6 ]
  %8 = phi i32 [ 0, %0 ], [ %11, %6 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !21)
    #dbg_value(i32 %8, !16, !DIExpression(), !20)
  %9 = ashr i32 %1, %7, !dbg !27
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !27
  %11 = add nsw i32 %10, %8, !dbg !29
    #dbg_value(i32 %11, !16, !DIExpression(), !20)
  %12 = add nuw nsw i32 %7, 1, !dbg !30
    #dbg_value(i32 %12, !17, !DIExpression(), !21)
  %13 = icmp eq i32 %12, 3, !dbg !31
  br i1 %13, label %2, label %6, !dbg !22, !llvm.loop !32
}

declare !dbg !36 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !41 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !44 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !45
    #dbg_value(i32 %1, !15, !DIExpression(), !47)
    #dbg_value(i32 0, !16, !DIExpression(), !47)
    #dbg_value(i32 1, !17, !DIExpression(), !48)
  br label %2, !dbg !49

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %8, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %7, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !48)
    #dbg_value(i32 %4, !16, !DIExpression(), !47)
  %5 = ashr i32 %1, %3, !dbg !50
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !50
  %7 = add nsw i32 %6, %4, !dbg !51
    #dbg_value(i32 %7, !16, !DIExpression(), !47)
  %8 = add nuw nsw i32 %3, 1, !dbg !52
    #dbg_value(i32 %8, !17, !DIExpression(), !48)
  %9 = icmp eq i32 %8, 3, !dbg !53
  br i1 %9, label %10, label %2, !dbg !49, !llvm.loop !54

10:                                               ; preds = %2
  %11 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !56
    #dbg_value(i32 %11, !15, !DIExpression(), !47)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !57
  %13 = add nsw i32 %12, %7, !dbg !58
  ret i32 %13, !dbg !59
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b5_measure_owned.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "b922eecd9265239ea5a1b88869034da3")
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
!23 = !DILocation(line: 10, column: 9, scope: !10)
!24 = !DILocation(line: 11, column: 16, scope: !10)
!25 = !DILocation(line: 11, column: 14, scope: !10)
!26 = !DILocation(line: 11, column: 5, scope: !10)
!27 = !DILocation(line: 9, column: 14, scope: !28)
!28 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!29 = !DILocation(line: 9, column: 11, scope: !28)
!30 = !DILocation(line: 8, column: 29, scope: !28)
!31 = !DILocation(line: 8, column: 23, scope: !28)
!32 = distinct !{!32, !22, !33, !34, !35}
!33 = !DILocation(line: 9, column: 14, scope: !18)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.unroll.disable"}
!36 = !DISubprogram(name: "cq_theta_si32", scope: !37, file: !37, line: 38, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!38 = !DISubroutineType(types: !39)
!39 = !{!13, !13, !40}
!40 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!41 = !DISubprogram(name: "cq_measure_si32", scope: !37, file: !37, line: 83, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DISubroutineType(types: !43)
!43 = !{!13, !13}
!44 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!45 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !46)
!46 = distinct !DILocation(line: 13, column: 25, scope: !44)
!47 = !DILocation(line: 0, scope: !10, inlinedAt: !46)
!48 = !DILocation(line: 0, scope: !18, inlinedAt: !46)
!49 = !DILocation(line: 8, column: 5, scope: !18, inlinedAt: !46)
!50 = !DILocation(line: 9, column: 14, scope: !28, inlinedAt: !46)
!51 = !DILocation(line: 9, column: 11, scope: !28, inlinedAt: !46)
!52 = !DILocation(line: 8, column: 29, scope: !28, inlinedAt: !46)
!53 = !DILocation(line: 8, column: 23, scope: !28, inlinedAt: !46)
!54 = distinct !{!54, !49, !55, !34, !35}
!55 = !DILocation(line: 9, column: 14, scope: !18, inlinedAt: !46)
!56 = !DILocation(line: 10, column: 9, scope: !10, inlinedAt: !46)
!57 = !DILocation(line: 11, column: 16, scope: !10, inlinedAt: !46)
!58 = !DILocation(line: 11, column: 14, scope: !10, inlinedAt: !46)
!59 = !DILocation(line: 13, column: 18, scope: !44)
