; ModuleID = 's4_inplace_accum_live.c'
source_filename = "s4_inplace_accum_live.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2, !dbg !19
    #dbg_value(i32 %1, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 1, !17, !DIExpression(), !21)
  br label %6, !dbg !22

2:                                                ; preds = %6
  %3 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #2, !dbg !23
    #dbg_value(i32 %3, !15, !DIExpression(), !20)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !24
  %5 = add nsw i32 %4, %13, !dbg !25
  ret i32 %5, !dbg !26

6:                                                ; preds = %0, %6
  %7 = phi i32 [ 1, %0 ], [ %14, %6 ]
  %8 = phi i32 [ 0, %0 ], [ %13, %6 ]
  %9 = phi i32 [ %1, %0 ], [ %10, %6 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !21)
    #dbg_value(i32 %8, !16, !DIExpression(), !20)
    #dbg_value(i32 %9, !15, !DIExpression(), !20)
  %10 = add nsw i32 %7, %9, !dbg !27
    #dbg_value(i32 %10, !15, !DIExpression(), !20)
  %11 = and i32 %10, 1, !dbg !30
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !30
  %13 = add nsw i32 %12, %8, !dbg !31
    #dbg_value(i32 %13, !16, !DIExpression(), !20)
  %14 = add nuw nsw i32 %7, 1, !dbg !32
    #dbg_value(i32 %14, !17, !DIExpression(), !21)
  %15 = icmp eq i32 %14, 5, !dbg !33
  br i1 %15, label %2, label %6, !dbg !22, !llvm.loop !34
}

declare !dbg !38 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !43 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !46 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2, !dbg !47
    #dbg_value(i32 %1, !15, !DIExpression(), !49)
    #dbg_value(i32 0, !16, !DIExpression(), !49)
    #dbg_value(i32 1, !17, !DIExpression(), !50)
  br label %2, !dbg !51

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %10, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %9, %2 ]
  %5 = phi i32 [ %1, %0 ], [ %6, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !50)
    #dbg_value(i32 %4, !16, !DIExpression(), !49)
    #dbg_value(i32 %5, !15, !DIExpression(), !49)
  %6 = add nsw i32 %5, %3, !dbg !52
    #dbg_value(i32 %6, !15, !DIExpression(), !49)
  %7 = and i32 %6, 1, !dbg !53
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !53
  %9 = add nsw i32 %8, %4, !dbg !54
    #dbg_value(i32 %9, !16, !DIExpression(), !49)
  %10 = add nuw nsw i32 %3, 1, !dbg !55
    #dbg_value(i32 %10, !17, !DIExpression(), !50)
  %11 = icmp eq i32 %10, 5, !dbg !56
  br i1 %11, label %12, label %2, !dbg !51, !llvm.loop !57

12:                                               ; preds = %2
  %13 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 9.000000e-01) #2, !dbg !59
    #dbg_value(i32 %13, !15, !DIExpression(), !49)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !60
  %15 = add nsw i32 %14, %9, !dbg !61
  ret i32 %15, !dbg !62
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
!8 = !DIFile(filename: "s4_inplace_accum_live.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "3206ea1f92723a09634d774d223024ab")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 11, type: !11, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 12, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 13, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 14, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 14, column: 5)
!19 = !DILocation(line: 12, column: 13, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 14, column: 5, scope: !18)
!23 = !DILocation(line: 18, column: 9, scope: !10)
!24 = !DILocation(line: 19, column: 16, scope: !10)
!25 = !DILocation(line: 19, column: 14, scope: !10)
!26 = !DILocation(line: 19, column: 5, scope: !10)
!27 = !DILocation(line: 15, column: 15, scope: !28)
!28 = distinct !DILexicalBlock(scope: !29, file: !8, line: 14, column: 34)
!29 = distinct !DILexicalBlock(scope: !18, file: !8, line: 14, column: 5)
!30 = !DILocation(line: 16, column: 14, scope: !28)
!31 = !DILocation(line: 16, column: 11, scope: !28)
!32 = !DILocation(line: 14, column: 29, scope: !29)
!33 = !DILocation(line: 14, column: 23, scope: !29)
!34 = distinct !{!34, !22, !35, !36, !37}
!35 = !DILocation(line: 17, column: 5, scope: !18)
!36 = !{!"llvm.loop.mustprogress"}
!37 = !{!"llvm.loop.unroll.disable"}
!38 = !DISubprogram(name: "cq_theta_si32", scope: !39, file: !39, line: 38, type: !40, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!39 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_S", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!40 = !DISubroutineType(types: !41)
!41 = !{!13, !13, !42}
!42 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!43 = !DISubprogram(name: "cq_measure_si32", scope: !39, file: !39, line: 83, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DISubroutineType(types: !45)
!45 = !{!13, !13}
!46 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 21, type: !11, scopeLine: 21, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!47 = !DILocation(line: 12, column: 13, scope: !10, inlinedAt: !48)
!48 = distinct !DILocation(line: 21, column: 25, scope: !46)
!49 = !DILocation(line: 0, scope: !10, inlinedAt: !48)
!50 = !DILocation(line: 0, scope: !18, inlinedAt: !48)
!51 = !DILocation(line: 14, column: 5, scope: !18, inlinedAt: !48)
!52 = !DILocation(line: 15, column: 15, scope: !28, inlinedAt: !48)
!53 = !DILocation(line: 16, column: 14, scope: !28, inlinedAt: !48)
!54 = !DILocation(line: 16, column: 11, scope: !28, inlinedAt: !48)
!55 = !DILocation(line: 14, column: 29, scope: !29, inlinedAt: !48)
!56 = !DILocation(line: 14, column: 23, scope: !29, inlinedAt: !48)
!57 = distinct !{!57, !51, !58, !36, !37}
!58 = !DILocation(line: 17, column: 5, scope: !18, inlinedAt: !48)
!59 = !DILocation(line: 18, column: 9, scope: !10, inlinedAt: !48)
!60 = !DILocation(line: 19, column: 16, scope: !10, inlinedAt: !48)
!61 = !DILocation(line: 19, column: 14, scope: !10, inlinedAt: !48)
!62 = !DILocation(line: 21, column: 18, scope: !46)
