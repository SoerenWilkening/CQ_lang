; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/w2k_noregion_invread.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/w2k_noregion_invread.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i32 %1, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
  %2 = and i32 %1, 1
  br label %6, !dbg !25

3:                                                ; preds = %6
  %4 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !26
  %5 = add nsw i32 %4, %15, !dbg !27
  ret i32 %5, !dbg !28

6:                                                ; preds = %0, %6
  %7 = phi i32 [ 0, %0 ], [ %15, %6 ]
  %8 = phi i32 [ 0, %0 ], [ %16, %6 ]
    #dbg_value(i32 %7, !16, !DIExpression(), !23)
    #dbg_value(i32 %8, !17, !DIExpression(), !24)
  %9 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !29
    #dbg_value(i32 %9, !19, !DIExpression(), !30)
  %10 = lshr i32 %9, 1, !dbg !31
  %11 = and i32 %10, 1, !dbg !31
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !31
  %13 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !32
  %14 = add i32 %12, %7, !dbg !33
  %15 = add i32 %14, %13, !dbg !34
    #dbg_value(i32 %15, !16, !DIExpression(), !23)
  %16 = add nuw nsw i32 %8, 1, !dbg !35
    #dbg_value(i32 %16, !17, !DIExpression(), !24)
  %17 = icmp eq i32 %8, 0, !dbg !36
  br i1 %17, label %6, label %3, !dbg !25, !llvm.loop !37
}

declare !dbg !41 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !46 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !49 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !50
    #dbg_value(i32 %1, !15, !DIExpression(), !52)
    #dbg_value(i32 0, !16, !DIExpression(), !52)
    #dbg_value(i32 0, !17, !DIExpression(), !53)
  %2 = and i32 %1, 1
  br label %3, !dbg !54

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %12, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %13, %3 ]
    #dbg_value(i32 %4, !16, !DIExpression(), !52)
    #dbg_value(i32 %5, !17, !DIExpression(), !53)
  %6 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !55
    #dbg_value(i32 %6, !19, !DIExpression(), !56)
  %7 = lshr i32 %6, 1, !dbg !57
  %8 = and i32 %7, 1, !dbg !57
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !57
  %10 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !58
  %11 = add i32 %9, %4, !dbg !59
  %12 = add i32 %11, %10, !dbg !60
    #dbg_value(i32 %12, !16, !DIExpression(), !52)
  %13 = add nuw nsw i32 %5, 1, !dbg !61
    #dbg_value(i32 %13, !17, !DIExpression(), !53)
  %14 = icmp eq i32 %5, 0, !dbg !62
  br i1 %14, label %3, label %15, !dbg !54, !llvm.loop !63

15:                                               ; preds = %3
  %16 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !65
  %17 = add nsw i32 %16, %12, !dbg !66
  ret i32 %17, !dbg !67
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/w2k_noregion_invread.c", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "480b45c8d804b748ad41363582d5290f")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 9, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 10, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 9, column: 33)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 9, column: 5)
!22 = !DILocation(line: 7, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 9, column: 5, scope: !18)
!26 = !DILocation(line: 13, column: 16, scope: !10)
!27 = !DILocation(line: 13, column: 14, scope: !10)
!28 = !DILocation(line: 13, column: 5, scope: !10)
!29 = !DILocation(line: 10, column: 17, scope: !20)
!30 = !DILocation(line: 0, scope: !20)
!31 = !DILocation(line: 11, column: 14, scope: !20)
!32 = !DILocation(line: 11, column: 41, scope: !20)
!33 = !DILocation(line: 11, column: 39, scope: !20)
!34 = !DILocation(line: 11, column: 11, scope: !20)
!35 = !DILocation(line: 9, column: 28, scope: !21)
!36 = !DILocation(line: 9, column: 23, scope: !21)
!37 = distinct !{!37, !25, !38, !39, !40}
!38 = !DILocation(line: 12, column: 5, scope: !18)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !{!"llvm.loop.unroll.disable"}
!41 = !DISubprogram(name: "cq_theta_si32", scope: !42, file: !42, line: 38, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!43 = !DISubroutineType(types: !44)
!44 = !{!13, !13, !45}
!45 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!46 = !DISubprogram(name: "cq_measure_si32", scope: !42, file: !42, line: 83, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DISubroutineType(types: !48)
!48 = !{!13, !13}
!49 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!50 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !51)
!51 = distinct !DILocation(line: 15, column: 25, scope: !49)
!52 = !DILocation(line: 0, scope: !10, inlinedAt: !51)
!53 = !DILocation(line: 0, scope: !18, inlinedAt: !51)
!54 = !DILocation(line: 9, column: 5, scope: !18, inlinedAt: !51)
!55 = !DILocation(line: 10, column: 17, scope: !20, inlinedAt: !51)
!56 = !DILocation(line: 0, scope: !20, inlinedAt: !51)
!57 = !DILocation(line: 11, column: 14, scope: !20, inlinedAt: !51)
!58 = !DILocation(line: 11, column: 41, scope: !20, inlinedAt: !51)
!59 = !DILocation(line: 11, column: 39, scope: !20, inlinedAt: !51)
!60 = !DILocation(line: 11, column: 11, scope: !20, inlinedAt: !51)
!61 = !DILocation(line: 9, column: 28, scope: !21, inlinedAt: !51)
!62 = !DILocation(line: 9, column: 23, scope: !21, inlinedAt: !51)
!63 = distinct !{!63, !54, !64, !39, !40}
!64 = !DILocation(line: 12, column: 5, scope: !18, inlinedAt: !51)
!65 = !DILocation(line: 13, column: 16, scope: !10, inlinedAt: !51)
!66 = !DILocation(line: 13, column: 14, scope: !10, inlinedAt: !51)
!67 = !DILocation(line: 15, column: 18, scope: !49)
