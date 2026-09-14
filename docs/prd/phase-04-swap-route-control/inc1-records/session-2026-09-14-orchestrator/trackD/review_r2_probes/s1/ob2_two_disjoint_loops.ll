; ModuleID = 'src/ob2_two_disjoint_loops.c'
source_filename = "src/ob2_two_disjoint_loops.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !26)
    #dbg_value(i32 0, !16, !DIExpression(), !27)
  br label %1, !dbg !28

1:                                                ; preds = %0, %1
  %2 = phi i32 [ 0, %0 ], [ %7, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %8, %1 ]
    #dbg_value(i32 %2, !15, !DIExpression(), !26)
    #dbg_value(i32 %3, !16, !DIExpression(), !27)
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !29
    #dbg_value(i32 %4, !18, !DIExpression(), !30)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 1.000000e-01) #2, !dbg !31
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !31
  %7 = add nsw i32 %6, %2, !dbg !32
    #dbg_value(i32 %7, !15, !DIExpression(), !26)
  %8 = add nuw nsw i32 %3, 1, !dbg !33
    #dbg_value(i32 %8, !16, !DIExpression(), !27)
  %9 = icmp eq i32 %8, 3, !dbg !34
  br i1 %9, label %11, label %1, !dbg !28, !llvm.loop !35

10:                                               ; preds = %11
  ret i32 %17, !dbg !39

11:                                               ; preds = %1, %11
  %12 = phi i32 [ %17, %11 ], [ %7, %1 ]
  %13 = phi i32 [ %18, %11 ], [ 0, %1 ]
    #dbg_value(i32 %12, !15, !DIExpression(), !26)
    #dbg_value(i32 %13, !21, !DIExpression(), !40)
  %14 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01) #2, !dbg !41
    #dbg_value(i32 %14, !23, !DIExpression(), !42)
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 2.000000e-01) #2, !dbg !43
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !43
  %17 = add nsw i32 %16, %12, !dbg !44
    #dbg_value(i32 %17, !15, !DIExpression(), !26)
  %18 = add nuw nsw i32 %13, 1, !dbg !45
    #dbg_value(i32 %18, !21, !DIExpression(), !40)
  %19 = icmp eq i32 %18, 3, !dbg !46
  br i1 %19, label %10, label %11, !dbg !47, !llvm.loop !48
}

declare !dbg !50 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !55 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/ob2_two_disjoint_loops.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "8bbf42a19d783ce0590872fbca61c048")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18, !21, !23}
!15 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "i", scope: !17, file: !8, line: 4, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!18 = !DILocalVariable(name: "q", scope: !19, file: !8, line: 4, type: !13)
!19 = distinct !DILexicalBlock(scope: !20, file: !8, line: 4, column: 23)
!20 = distinct !DILexicalBlock(scope: !17, file: !8, line: 4, column: 3)
!21 = !DILocalVariable(name: "j", scope: !22, file: !8, line: 5, type: !13)
!22 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 3)
!23 = !DILocalVariable(name: "r", scope: !24, file: !8, line: 5, type: !13)
!24 = distinct !DILexicalBlock(scope: !25, file: !8, line: 5, column: 23)
!25 = distinct !DILexicalBlock(scope: !22, file: !8, line: 5, column: 3)
!26 = !DILocation(line: 0, scope: !10)
!27 = !DILocation(line: 0, scope: !17)
!28 = !DILocation(line: 4, column: 3, scope: !17)
!29 = !DILocation(line: 4, column: 31, scope: !19)
!30 = !DILocation(line: 0, scope: !19)
!31 = !DILocation(line: 4, column: 51, scope: !19)
!32 = !DILocation(line: 4, column: 49, scope: !19)
!33 = !DILocation(line: 4, column: 20, scope: !20)
!34 = !DILocation(line: 4, column: 16, scope: !20)
!35 = distinct !{!35, !28, !36, !37, !38}
!36 = !DILocation(line: 4, column: 80, scope: !17)
!37 = !{!"llvm.loop.mustprogress"}
!38 = !{!"llvm.loop.unroll.disable"}
!39 = !DILocation(line: 6, column: 3, scope: !10)
!40 = !DILocation(line: 0, scope: !22)
!41 = !DILocation(line: 5, column: 31, scope: !24)
!42 = !DILocation(line: 0, scope: !24)
!43 = !DILocation(line: 5, column: 51, scope: !24)
!44 = !DILocation(line: 5, column: 49, scope: !24)
!45 = !DILocation(line: 5, column: 20, scope: !25)
!46 = !DILocation(line: 5, column: 16, scope: !25)
!47 = !DILocation(line: 5, column: 3, scope: !22)
!48 = distinct !{!48, !47, !49, !37, !38}
!49 = !DILocation(line: 5, column: 80, scope: !22)
!50 = !DISubprogram(name: "cq_theta_si32", scope: !51, file: !51, line: 38, type: !52, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!52 = !DISubroutineType(types: !53)
!53 = !{!13, !13, !54}
!54 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!55 = !DISubprogram(name: "cq_measure_si32", scope: !51, file: !51, line: 83, type: !56, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!56 = !DISubroutineType(types: !57)
!57 = !{!13, !13}
