; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/b2_readafter_nonlive.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/b2_readafter_nonlive.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !20
    #dbg_value(i32 %1, !15, !DIExpression(), !21)
  %2 = and i32 %1, 1, !dbg !22
    #dbg_value(i32 %2, !16, !DIExpression(), !21)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
    #dbg_value(i32 1, !18, !DIExpression(), !23)
  br label %9, !dbg !24

3:                                                ; preds = %9
  %4 = add nuw nsw i32 %2, 1, !dbg !25
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2, !dbg !25
  %6 = add nsw i32 %5, %17, !dbg !26
  %7 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !27
  %8 = add nsw i32 %6, %7, !dbg !28
  ret i32 %8, !dbg !29

9:                                                ; preds = %0, %9
  %10 = phi i32 [ 1, %0 ], [ %18, %9 ]
  %11 = phi i32 [ 0, %0 ], [ %17, %9 ]
    #dbg_value(i32 %10, !18, !DIExpression(), !23)
    #dbg_value(i32 %11, !17, !DIExpression(), !21)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !30
  %13 = lshr i32 %1, %10, !dbg !32
  %14 = and i32 %13, 1, !dbg !32
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2, !dbg !32
  %16 = add i32 %12, %11, !dbg !33
  %17 = add i32 %16, %15, !dbg !34
    #dbg_value(i32 %17, !17, !DIExpression(), !21)
  %18 = add nuw nsw i32 %10, 1, !dbg !35
    #dbg_value(i32 %18, !18, !DIExpression(), !23)
  %19 = icmp eq i32 %18, 3, !dbg !36
  br i1 %19, label %3, label %9, !dbg !24, !llvm.loop !37
}

declare !dbg !41 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !46 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !49 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !50
    #dbg_value(i32 %1, !15, !DIExpression(), !52)
  %2 = and i32 %1, 1, !dbg !53
    #dbg_value(i32 %2, !16, !DIExpression(), !52)
    #dbg_value(i32 0, !17, !DIExpression(), !52)
    #dbg_value(i32 1, !18, !DIExpression(), !54)
  br label %3, !dbg !55

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 1, %0 ], [ %12, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %11, %3 ]
    #dbg_value(i32 %4, !18, !DIExpression(), !54)
    #dbg_value(i32 %5, !17, !DIExpression(), !52)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !56
  %7 = lshr i32 %1, %4, !dbg !57
  %8 = and i32 %7, 1, !dbg !57
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !57
  %10 = add i32 %6, %5, !dbg !58
  %11 = add i32 %10, %9, !dbg !59
    #dbg_value(i32 %11, !17, !DIExpression(), !52)
  %12 = add nuw nsw i32 %4, 1, !dbg !60
    #dbg_value(i32 %12, !18, !DIExpression(), !54)
  %13 = icmp eq i32 %12, 3, !dbg !61
  br i1 %13, label %14, label %3, !dbg !55, !llvm.loop !62

14:                                               ; preds = %3
  %15 = add nuw nsw i32 %2, 1, !dbg !64
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !64
  %17 = add nsw i32 %16, %11, !dbg !65
  %18 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !66
  %19 = add nsw i32 %17, %18, !dbg !67
  ret i32 %19, !dbg !68
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/b2_readafter_nonlive.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "048c9f874b69ee6b3338084e1a408c40")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 9, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!20 = !DILocation(line: 6, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 7, column: 15, scope: !10)
!23 = !DILocation(line: 0, scope: !19)
!24 = !DILocation(line: 9, column: 5, scope: !19)
!25 = !DILocation(line: 11, column: 16, scope: !10)
!26 = !DILocation(line: 11, column: 14, scope: !10)
!27 = !DILocation(line: 11, column: 36, scope: !10)
!28 = !DILocation(line: 11, column: 34, scope: !10)
!29 = !DILocation(line: 11, column: 5, scope: !10)
!30 = !DILocation(line: 10, column: 14, scope: !31)
!31 = distinct !DILexicalBlock(scope: !19, file: !8, line: 9, column: 5)
!32 = !DILocation(line: 10, column: 30, scope: !31)
!33 = !DILocation(line: 10, column: 28, scope: !31)
!34 = !DILocation(line: 10, column: 11, scope: !31)
!35 = !DILocation(line: 9, column: 29, scope: !31)
!36 = !DILocation(line: 9, column: 23, scope: !31)
!37 = distinct !{!37, !24, !38, !39, !40}
!38 = !DILocation(line: 10, column: 30, scope: !19)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !{!"llvm.loop.unroll.disable"}
!41 = !DISubprogram(name: "cq_theta_si32", scope: !42, file: !42, line: 38, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!43 = !DISubroutineType(types: !44)
!44 = !{!13, !13, !45}
!45 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!46 = !DISubprogram(name: "cq_measure_si32", scope: !42, file: !42, line: 83, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DISubroutineType(types: !48)
!48 = !{!13, !13}
!49 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!50 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !51)
!51 = distinct !DILocation(line: 13, column: 25, scope: !49)
!52 = !DILocation(line: 0, scope: !10, inlinedAt: !51)
!53 = !DILocation(line: 7, column: 15, scope: !10, inlinedAt: !51)
!54 = !DILocation(line: 0, scope: !19, inlinedAt: !51)
!55 = !DILocation(line: 9, column: 5, scope: !19, inlinedAt: !51)
!56 = !DILocation(line: 10, column: 14, scope: !31, inlinedAt: !51)
!57 = !DILocation(line: 10, column: 30, scope: !31, inlinedAt: !51)
!58 = !DILocation(line: 10, column: 28, scope: !31, inlinedAt: !51)
!59 = !DILocation(line: 10, column: 11, scope: !31, inlinedAt: !51)
!60 = !DILocation(line: 9, column: 29, scope: !31, inlinedAt: !51)
!61 = !DILocation(line: 9, column: 23, scope: !31, inlinedAt: !51)
!62 = distinct !{!62, !55, !63, !39, !40}
!63 = !DILocation(line: 10, column: 30, scope: !19, inlinedAt: !51)
!64 = !DILocation(line: 11, column: 16, scope: !10, inlinedAt: !51)
!65 = !DILocation(line: 11, column: 14, scope: !10, inlinedAt: !51)
!66 = !DILocation(line: 11, column: 36, scope: !10, inlinedAt: !51)
!67 = !DILocation(line: 11, column: 34, scope: !10, inlinedAt: !51)
!68 = !DILocation(line: 13, column: 18, scope: !49)
