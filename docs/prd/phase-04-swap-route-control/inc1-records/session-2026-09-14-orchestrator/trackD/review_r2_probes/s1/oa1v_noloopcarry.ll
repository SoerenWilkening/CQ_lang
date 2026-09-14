; ModuleID = 'src/oa1v_noloopcarry.c'
source_filename = "src/oa1v_noloopcarry.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !24)
  br label %2, !dbg !25

1:                                                ; preds = %2
  ret i32 %9, !dbg !26

2:                                                ; preds = %0, %2
  %3 = phi i32 [ 0, %0 ], [ %9, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %10, %2 ]
    #dbg_value(i32 %3, !15, !DIExpression(), !23)
    #dbg_value(i32 %4, !16, !DIExpression(), !24)
  %5 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !27
    #dbg_value(i32 %5, !18, !DIExpression(), !28)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 1.000000e-01) #2, !dbg !29
    #dbg_value(i32 %6, !21, !DIExpression(), !28)
  %7 = add nsw i32 %6, 1, !dbg !30
    #dbg_value(i32 %7, !22, !DIExpression(), !28)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !31
  %9 = add nsw i32 %8, %3, !dbg !32
    #dbg_value(i32 %9, !15, !DIExpression(), !23)
  %10 = add nuw nsw i32 %4, 1, !dbg !33
    #dbg_value(i32 %10, !16, !DIExpression(), !24)
  %11 = icmp eq i32 %10, 3, !dbg !34
  br i1 %11, label %1, label %2, !dbg !25, !llvm.loop !35
}

declare !dbg !39 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !44 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/oa1v_noloopcarry.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "28015e0e2e66d38630f1cc02a6c9f811")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18, !21, !22}
!15 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "i", scope: !17, file: !8, line: 5, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 3)
!18 = !DILocalVariable(name: "q", scope: !19, file: !8, line: 5, type: !13)
!19 = distinct !DILexicalBlock(scope: !20, file: !8, line: 5, column: 23)
!20 = distinct !DILexicalBlock(scope: !17, file: !8, line: 5, column: 3)
!21 = !DILocalVariable(name: "a", scope: !19, file: !8, line: 5, type: !13)
!22 = !DILocalVariable(name: "d", scope: !19, file: !8, line: 5, type: !13)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !17)
!25 = !DILocation(line: 5, column: 3, scope: !17)
!26 = !DILocation(line: 6, column: 3, scope: !10)
!27 = !DILocation(line: 5, column: 31, scope: !19)
!28 = !DILocation(line: 0, scope: !19)
!29 = !DILocation(line: 5, column: 54, scope: !19)
!30 = !DILocation(line: 5, column: 78, scope: !19)
!31 = !DILocation(line: 5, column: 85, scope: !19)
!32 = !DILocation(line: 5, column: 83, scope: !19)
!33 = !DILocation(line: 5, column: 20, scope: !20)
!34 = !DILocation(line: 5, column: 16, scope: !20)
!35 = distinct !{!35, !25, !36, !37, !38}
!36 = !DILocation(line: 5, column: 100, scope: !17)
!37 = !{!"llvm.loop.mustprogress"}
!38 = !{!"llvm.loop.unroll.disable"}
!39 = !DISubprogram(name: "cq_theta_si32", scope: !40, file: !40, line: 38, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!40 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!41 = !DISubroutineType(types: !42)
!42 = !{!13, !13, !43}
!43 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!44 = !DISubprogram(name: "cq_measure_si32", scope: !40, file: !40, line: 83, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DISubroutineType(types: !46)
!46 = !{!13, !13}
