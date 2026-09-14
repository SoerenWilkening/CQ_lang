; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a4_invariant_measured_and_read_after.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a4_invariant_measured_and_read_after.c"
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
  br label %10, !dbg !24

3:                                                ; preds = %10
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !25
    #dbg_value(i32 %4, !15, !DIExpression(), !21)
  %5 = add nuw nsw i32 %2, 1, !dbg !26
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !26
  %7 = add nsw i32 %6, %18, !dbg !27
  %8 = tail call i32 @cq_measure_si32(i32 noundef %4) #2, !dbg !28
  %9 = add nsw i32 %7, %8, !dbg !29
  ret i32 %9, !dbg !30

10:                                               ; preds = %0, %10
  %11 = phi i32 [ 1, %0 ], [ %19, %10 ]
  %12 = phi i32 [ 0, %0 ], [ %18, %10 ]
    #dbg_value(i32 %11, !18, !DIExpression(), !23)
    #dbg_value(i32 %12, !17, !DIExpression(), !21)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !31
  %14 = lshr i32 %1, %11, !dbg !33
  %15 = and i32 %14, 1, !dbg !33
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !33
  %17 = add i32 %13, %12, !dbg !34
  %18 = add i32 %17, %16, !dbg !35
    #dbg_value(i32 %18, !17, !DIExpression(), !21)
  %19 = add nuw nsw i32 %11, 1, !dbg !36
    #dbg_value(i32 %19, !18, !DIExpression(), !23)
  %20 = icmp eq i32 %19, 3, !dbg !37
  br i1 %20, label %3, label %10, !dbg !24, !llvm.loop !38
}

declare !dbg !42 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !47 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !50 {
  %1 = tail call i32 @slice(), !dbg !51
  ret i32 %1, !dbg !52
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a4_invariant_measured_and_read_after.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "82c7abb626d959b0925ad217614f32dd")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 5, type: !13)
!16 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 6, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 8, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!20 = !DILocation(line: 5, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 6, column: 15, scope: !10)
!23 = !DILocation(line: 0, scope: !19)
!24 = !DILocation(line: 8, column: 5, scope: !19)
!25 = !DILocation(line: 10, column: 9, scope: !10)
!26 = !DILocation(line: 11, column: 16, scope: !10)
!27 = !DILocation(line: 11, column: 14, scope: !10)
!28 = !DILocation(line: 11, column: 36, scope: !10)
!29 = !DILocation(line: 11, column: 34, scope: !10)
!30 = !DILocation(line: 11, column: 5, scope: !10)
!31 = !DILocation(line: 9, column: 14, scope: !32)
!32 = distinct !DILexicalBlock(scope: !19, file: !8, line: 8, column: 5)
!33 = !DILocation(line: 9, column: 30, scope: !32)
!34 = !DILocation(line: 9, column: 28, scope: !32)
!35 = !DILocation(line: 9, column: 11, scope: !32)
!36 = !DILocation(line: 8, column: 29, scope: !32)
!37 = !DILocation(line: 8, column: 23, scope: !32)
!38 = distinct !{!38, !24, !39, !40, !41}
!39 = !DILocation(line: 9, column: 30, scope: !19)
!40 = !{!"llvm.loop.mustprogress"}
!41 = !{!"llvm.loop.unroll.disable"}
!42 = !DISubprogram(name: "cq_theta_si32", scope: !43, file: !43, line: 38, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!44 = !DISubroutineType(types: !45)
!45 = !{!13, !13, !46}
!46 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!47 = !DISubprogram(name: "cq_measure_si32", scope: !43, file: !43, line: 83, type: !48, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!48 = !DISubroutineType(types: !49)
!49 = !{!13, !13}
!50 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!51 = !DILocation(line: 13, column: 25, scope: !50)
!52 = !DILocation(line: 13, column: 18, scope: !50)
