; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a7_two_registers.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a7_two_registers.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !20
    #dbg_value(i32 %1, !15, !DIExpression(), !21)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !22
    #dbg_value(i32 %2, !16, !DIExpression(), !21)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
    #dbg_value(i32 1, !18, !DIExpression(), !23)
  br label %10, !dbg !24

3:                                                ; preds = %10
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !25
    #dbg_value(i32 %4, !15, !DIExpression(), !21)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 0x3FE6666666666666) #2, !dbg !26
    #dbg_value(i32 %5, !16, !DIExpression(), !21)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %4) #2, !dbg !27
  %7 = add nsw i32 %6, %19, !dbg !28
  %8 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !29
  %9 = add nsw i32 %7, %8, !dbg !30
  ret i32 %9, !dbg !31

10:                                               ; preds = %0, %10
  %11 = phi i32 [ 1, %0 ], [ %20, %10 ]
  %12 = phi i32 [ 0, %0 ], [ %19, %10 ]
    #dbg_value(i32 %11, !18, !DIExpression(), !23)
    #dbg_value(i32 %12, !17, !DIExpression(), !21)
  %13 = lshr i32 %1, %11, !dbg !32
  %14 = and i32 %13, 1, !dbg !32
  %15 = lshr i32 %2, %11, !dbg !32
  %16 = and i32 %15, 1, !dbg !32
  %17 = add nuw nsw i32 %14, %16, !dbg !32
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #2, !dbg !32
  %19 = add nsw i32 %18, %12, !dbg !34
    #dbg_value(i32 %19, !17, !DIExpression(), !21)
  %20 = add nuw nsw i32 %11, 1, !dbg !35
    #dbg_value(i32 %20, !18, !DIExpression(), !23)
  %21 = icmp eq i32 %20, 3, !dbg !36
  br i1 %21, label %3, label %10, !dbg !24, !llvm.loop !37
}

declare !dbg !41 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !46 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !49 {
  %1 = tail call i32 @slice(), !dbg !50
  ret i32 %1, !dbg !51
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a7_two_registers.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "c64e1048bb2af65baedafa1d6b234954")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 5, type: !13)
!16 = !DILocalVariable(name: "z", scope: !10, file: !8, line: 6, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 8, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!20 = !DILocation(line: 5, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 6, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !19)
!24 = !DILocation(line: 8, column: 5, scope: !19)
!25 = !DILocation(line: 10, column: 9, scope: !10)
!26 = !DILocation(line: 11, column: 9, scope: !10)
!27 = !DILocation(line: 12, column: 16, scope: !10)
!28 = !DILocation(line: 12, column: 14, scope: !10)
!29 = !DILocation(line: 12, column: 32, scope: !10)
!30 = !DILocation(line: 12, column: 30, scope: !10)
!31 = !DILocation(line: 12, column: 5, scope: !10)
!32 = !DILocation(line: 9, column: 14, scope: !33)
!33 = distinct !DILexicalBlock(scope: !19, file: !8, line: 8, column: 5)
!34 = !DILocation(line: 9, column: 11, scope: !33)
!35 = !DILocation(line: 8, column: 29, scope: !33)
!36 = !DILocation(line: 8, column: 23, scope: !33)
!37 = distinct !{!37, !24, !38, !39, !40}
!38 = !DILocation(line: 9, column: 14, scope: !19)
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
!49 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 14, type: !11, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!50 = !DILocation(line: 14, column: 25, scope: !49)
!51 = !DILocation(line: 14, column: 18, scope: !49)
