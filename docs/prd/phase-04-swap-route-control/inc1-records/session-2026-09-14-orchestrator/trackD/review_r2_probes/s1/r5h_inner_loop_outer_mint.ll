; ModuleID = 'src/r5h_inner_loop_outer_mint.c'
source_filename = "src/r5h_inner_loop_outer_mint.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !26)
    #dbg_value(i32 0, !16, !DIExpression(), !27)
  br label %2, !dbg !28

1:                                                ; preds = %6
  ret i32 %14, !dbg !29

2:                                                ; preds = %0, %6
  %3 = phi i32 [ 0, %0 ], [ %14, %6 ]
  %4 = phi i32 [ 0, %0 ], [ %7, %6 ]
    #dbg_value(i32 %3, !15, !DIExpression(), !26)
    #dbg_value(i32 %4, !16, !DIExpression(), !27)
  %5 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !30
    #dbg_value(i32 %5, !18, !DIExpression(), !31)
    #dbg_value(i32 0, !21, !DIExpression(), !32)
    #dbg_value(i32 %3, !15, !DIExpression(), !26)
  br label %9, !dbg !33

6:                                                ; preds = %9
  %7 = add nuw nsw i32 %4, 1, !dbg !34
    #dbg_value(i32 %14, !15, !DIExpression(), !26)
    #dbg_value(i32 %7, !16, !DIExpression(), !27)
  %8 = icmp eq i32 %4, 0, !dbg !35
  br i1 %8, label %2, label %1, !dbg !28, !llvm.loop !36

9:                                                ; preds = %2, %9
  %10 = phi i32 [ 0, %2 ], [ %15, %9 ]
  %11 = phi i32 [ %3, %2 ], [ %14, %9 ]
    #dbg_value(i32 %10, !21, !DIExpression(), !32)
    #dbg_value(i32 %11, !15, !DIExpression(), !26)
  %12 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 1.000000e-01) #2, !dbg !40
    #dbg_value(i32 %12, !23, !DIExpression(), !41)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !42
  %14 = add nsw i32 %13, %11, !dbg !43
    #dbg_value(i32 %14, !15, !DIExpression(), !26)
  %15 = add nuw nsw i32 %10, 1, !dbg !44
    #dbg_value(i32 %15, !21, !DIExpression(), !32)
  %16 = icmp eq i32 %10, 0, !dbg !45
  br i1 %16, label %9, label %6, !dbg !33, !llvm.loop !46
}

declare !dbg !48 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !53 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/r5h_inner_loop_outer_mint.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "7c96dedf1e5ad2c60aaa1cfdb3b9f451")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18, !21, !23}
!15 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "i", scope: !17, file: !8, line: 4, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 26)
!18 = !DILocalVariable(name: "q", scope: !19, file: !8, line: 4, type: !13)
!19 = distinct !DILexicalBlock(scope: !20, file: !8, line: 4, column: 46)
!20 = distinct !DILexicalBlock(scope: !17, file: !8, line: 4, column: 26)
!21 = !DILocalVariable(name: "j", scope: !22, file: !8, line: 5, type: !13)
!22 = distinct !DILexicalBlock(scope: !19, file: !8, line: 5, column: 3)
!23 = !DILocalVariable(name: "b", scope: !24, file: !8, line: 5, type: !13)
!24 = distinct !DILexicalBlock(scope: !25, file: !8, line: 5, column: 23)
!25 = distinct !DILexicalBlock(scope: !22, file: !8, line: 5, column: 3)
!26 = !DILocation(line: 0, scope: !10)
!27 = !DILocation(line: 0, scope: !17)
!28 = !DILocation(line: 4, column: 26, scope: !17)
!29 = !DILocation(line: 5, column: 80, scope: !10)
!30 = !DILocation(line: 4, column: 54, scope: !19)
!31 = !DILocation(line: 0, scope: !19)
!32 = !DILocation(line: 0, scope: !22)
!33 = !DILocation(line: 5, column: 3, scope: !22)
!34 = !DILocation(line: 4, column: 43, scope: !20)
!35 = !DILocation(line: 4, column: 39, scope: !20)
!36 = distinct !{!36, !28, !37, !38, !39}
!37 = !DILocation(line: 5, column: 68, scope: !17)
!38 = !{!"llvm.loop.mustprogress"}
!39 = !{!"llvm.loop.unroll.disable"}
!40 = !DILocation(line: 5, column: 31, scope: !24)
!41 = !DILocation(line: 0, scope: !24)
!42 = !DILocation(line: 5, column: 51, scope: !24)
!43 = !DILocation(line: 5, column: 49, scope: !24)
!44 = !DILocation(line: 5, column: 20, scope: !25)
!45 = !DILocation(line: 5, column: 16, scope: !25)
!46 = distinct !{!46, !33, !47, !38, !39}
!47 = !DILocation(line: 5, column: 66, scope: !22)
!48 = !DISubprogram(name: "cq_theta_si32", scope: !49, file: !49, line: 38, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!49 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!50 = !DISubroutineType(types: !51)
!51 = !{!13, !13, !52}
!52 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!53 = !DISubprogram(name: "cq_measure_si32", scope: !49, file: !49, line: 83, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!54 = !DISubroutineType(types: !55)
!55 = !{!13, !13}
