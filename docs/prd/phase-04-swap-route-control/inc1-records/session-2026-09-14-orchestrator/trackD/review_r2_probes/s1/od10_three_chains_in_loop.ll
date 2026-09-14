; ModuleID = 'src/od10_three_chains_in_loop.c'
source_filename = "src/od10_three_chains_in_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !21
    #dbg_value(i32 %1, !15, !DIExpression(), !22)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01) #2, !dbg !23
    #dbg_value(i32 %2, !16, !DIExpression(), !22)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2, !dbg !24
    #dbg_value(i32 %3, !17, !DIExpression(), !22)
    #dbg_value(i32 0, !18, !DIExpression(), !22)
    #dbg_value(i32 0, !19, !DIExpression(), !25)
    #dbg_value(i32 %2, !16, !DIExpression(), !22)
    #dbg_value(i32 %1, !15, !DIExpression(), !22)
  br label %5, !dbg !26

4:                                                ; preds = %5
  ret i32 %19, !dbg !27

5:                                                ; preds = %0, %5
  %6 = phi i32 [ 0, %0 ], [ %20, %5 ]
  %7 = phi i32 [ 0, %0 ], [ %19, %5 ]
  %8 = phi i32 [ %3, %0 ], [ %13, %5 ]
  %9 = phi i32 [ %2, %0 ], [ %12, %5 ]
  %10 = phi i32 [ %1, %0 ], [ %11, %5 ]
    #dbg_value(i32 %6, !19, !DIExpression(), !25)
    #dbg_value(i32 %7, !18, !DIExpression(), !22)
    #dbg_value(i32 %8, !17, !DIExpression(), !22)
    #dbg_value(i32 %9, !16, !DIExpression(), !22)
    #dbg_value(i32 %10, !15, !DIExpression(), !22)
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 1.000000e-01) #2, !dbg !28
    #dbg_value(i32 %11, !15, !DIExpression(), !22)
  %12 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 2.000000e-01) #2, !dbg !31
    #dbg_value(i32 %12, !16, !DIExpression(), !22)
  %13 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 1.500000e-01) #2, !dbg !32
    #dbg_value(i32 %13, !17, !DIExpression(), !22)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !33
  %15 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !34
  %16 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !35
  %17 = add i32 %14, %7, !dbg !36
  %18 = add i32 %17, %15, !dbg !37
  %19 = add i32 %18, %16, !dbg !38
    #dbg_value(i32 %19, !18, !DIExpression(), !22)
  %20 = add nuw nsw i32 %6, 1, !dbg !39
    #dbg_value(i32 %20, !19, !DIExpression(), !25)
  %21 = icmp eq i32 %20, 3, !dbg !40
  br i1 %21, label %4, label %5, !dbg !26, !llvm.loop !41
}

declare !dbg !45 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !50 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/od10_three_chains_in_loop.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "77431d62e08789682a6009818e09d435")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !19}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "r", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "t", scope: !10, file: !8, line: 3, type: !13)
!18 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!19 = !DILocalVariable(name: "i", scope: !20, file: !8, line: 4, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!21 = !DILocation(line: 3, column: 23, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 3, column: 46, scope: !10)
!24 = !DILocation(line: 3, column: 69, scope: !10)
!25 = !DILocation(line: 0, scope: !20)
!26 = !DILocation(line: 4, column: 3, scope: !20)
!27 = !DILocation(line: 5, column: 53, scope: !10)
!28 = !DILocation(line: 4, column: 27, scope: !29)
!29 = distinct !DILexicalBlock(scope: !30, file: !8, line: 4, column: 23)
!30 = distinct !DILexicalBlock(scope: !20, file: !8, line: 4, column: 3)
!31 = !DILocation(line: 4, column: 46, scope: !29)
!32 = !DILocation(line: 4, column: 65, scope: !29)
!33 = !DILocation(line: 5, column: 8, scope: !29)
!34 = !DILocation(line: 5, column: 22, scope: !29)
!35 = !DILocation(line: 5, column: 36, scope: !29)
!36 = !DILocation(line: 5, column: 21, scope: !29)
!37 = !DILocation(line: 5, column: 35, scope: !29)
!38 = !DILocation(line: 5, column: 6, scope: !29)
!39 = !DILocation(line: 4, column: 20, scope: !30)
!40 = !DILocation(line: 4, column: 16, scope: !30)
!41 = distinct !{!41, !26, !42, !43, !44}
!42 = !DILocation(line: 5, column: 51, scope: !20)
!43 = !{!"llvm.loop.mustprogress"}
!44 = !{!"llvm.loop.unroll.disable"}
!45 = !DISubprogram(name: "cq_theta_si32", scope: !46, file: !46, line: 38, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!47 = !DISubroutineType(types: !48)
!48 = !{!13, !13, !49}
!49 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!50 = !DISubprogram(name: "cq_measure_si32", scope: !46, file: !46, line: 83, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DISubroutineType(types: !52)
!52 = !{!13, !13}
