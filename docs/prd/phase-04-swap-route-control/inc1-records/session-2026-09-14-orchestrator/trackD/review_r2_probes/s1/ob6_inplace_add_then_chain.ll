; ModuleID = 'src/ob6_inplace_add_then_chain.c'
source_filename = "src/ob6_inplace_add_then_chain.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !19
    #dbg_value(i32 %1, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
  br label %3, !dbg !22

2:                                                ; preds = %3
  ret i32 %10, !dbg !23

3:                                                ; preds = %0, %3
  %4 = phi i32 [ 0, %0 ], [ %11, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %10, %3 ]
  %6 = phi i32 [ %1, %0 ], [ %8, %3 ]
    #dbg_value(i32 %4, !17, !DIExpression(), !21)
    #dbg_value(i32 %5, !16, !DIExpression(), !20)
    #dbg_value(i32 %6, !15, !DIExpression(), !20)
  %7 = add nsw i32 %6, 1, !dbg !24
    #dbg_value(i32 %7, !15, !DIExpression(), !20)
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 1.000000e-01) #2, !dbg !27
    #dbg_value(i32 %8, !15, !DIExpression(), !20)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !28
  %10 = add nsw i32 %9, %5, !dbg !29
    #dbg_value(i32 %10, !16, !DIExpression(), !20)
  %11 = add nuw nsw i32 %4, 1, !dbg !30
    #dbg_value(i32 %11, !17, !DIExpression(), !21)
  %12 = icmp eq i32 %11, 3, !dbg !31
  br i1 %12, label %2, label %3, !dbg !22, !llvm.loop !32
}

declare !dbg !36 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !41 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/ob6_inplace_add_then_chain.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "ece62f7b1094099a8f2ef87f342e2d8c")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 4, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!19 = !DILocation(line: 3, column: 23, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 4, column: 3, scope: !18)
!23 = !DILocation(line: 4, column: 71, scope: !10)
!24 = !DILocation(line: 4, column: 28, scope: !25)
!25 = distinct !DILexicalBlock(scope: !26, file: !8, line: 4, column: 23)
!26 = distinct !DILexicalBlock(scope: !18, file: !8, line: 4, column: 3)
!27 = !DILocation(line: 4, column: 34, scope: !25)
!28 = !DILocation(line: 4, column: 54, scope: !25)
!29 = !DILocation(line: 4, column: 52, scope: !25)
!30 = !DILocation(line: 4, column: 20, scope: !26)
!31 = !DILocation(line: 4, column: 16, scope: !26)
!32 = distinct !{!32, !22, !33, !34, !35}
!33 = !DILocation(line: 4, column: 69, scope: !18)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.unroll.disable"}
!36 = !DISubprogram(name: "cq_theta_si32", scope: !37, file: !37, line: 38, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!38 = !DISubroutineType(types: !39)
!39 = !{!13, !13, !40}
!40 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!41 = !DISubprogram(name: "cq_measure_si32", scope: !37, file: !37, line: 83, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DISubroutineType(types: !43)
!43 = !{!13, !13}
