; ModuleID = 'src/m14c_measure_then_inloop_reuse.c'
source_filename = "src/m14c_measure_then_inloop_reuse.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !23
    #dbg_value(i32 %1, !15, !DIExpression(), !24)
  %2 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !25
    #dbg_value(i32 %2, !16, !DIExpression(), !24)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
    #dbg_value(i32 0, !18, !DIExpression(), !26)
  br label %5, !dbg !27

3:                                                ; preds = %5
  %4 = add nsw i32 %10, %2, !dbg !28
  ret i32 %4, !dbg !29

5:                                                ; preds = %0, %5
  %6 = phi i32 [ 0, %0 ], [ %10, %5 ]
  %7 = phi i32 [ 0, %0 ], [ %11, %5 ]
    #dbg_value(i32 %6, !17, !DIExpression(), !24)
    #dbg_value(i32 %7, !18, !DIExpression(), !26)
  %8 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e-01) #2, !dbg !30
    #dbg_value(i32 %8, !20, !DIExpression(), !31)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !32
  %10 = add nsw i32 %9, %6, !dbg !33
    #dbg_value(i32 %10, !17, !DIExpression(), !24)
  %11 = add nuw nsw i32 %7, 1, !dbg !34
    #dbg_value(i32 %11, !18, !DIExpression(), !26)
  %12 = icmp eq i32 %11, 3, !dbg !35
  br i1 %12, label %3, label %5, !dbg !27, !llvm.loop !36
}

declare !dbg !40 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !45 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/m14c_measure_then_inloop_reuse.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "7785424f88cf2034af9435b6ca31671f")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !20}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 5, type: !13)
!16 = !DILocalVariable(name: "m", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!18 = !DILocalVariable(name: "i", scope: !19, file: !8, line: 6, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 3)
!20 = !DILocalVariable(name: "b", scope: !21, file: !8, line: 6, type: !13)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 6, column: 23)
!22 = distinct !DILexicalBlock(scope: !19, file: !8, line: 6, column: 3)
!23 = !DILocation(line: 5, column: 23, scope: !10)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 5, column: 46, scope: !10)
!26 = !DILocation(line: 0, scope: !19)
!27 = !DILocation(line: 6, column: 3, scope: !19)
!28 = !DILocation(line: 6, column: 76, scope: !10)
!29 = !DILocation(line: 6, column: 68, scope: !10)
!30 = !DILocation(line: 6, column: 31, scope: !21)
!31 = !DILocation(line: 0, scope: !21)
!32 = !DILocation(line: 6, column: 51, scope: !21)
!33 = !DILocation(line: 6, column: 49, scope: !21)
!34 = !DILocation(line: 6, column: 20, scope: !22)
!35 = !DILocation(line: 6, column: 16, scope: !22)
!36 = distinct !{!36, !27, !37, !38, !39}
!37 = !DILocation(line: 6, column: 66, scope: !19)
!38 = !{!"llvm.loop.mustprogress"}
!39 = !{!"llvm.loop.unroll.disable"}
!40 = !DISubprogram(name: "cq_theta_si32", scope: !41, file: !41, line: 38, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!42 = !DISubroutineType(types: !43)
!43 = !{!13, !13, !44}
!44 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!45 = !DISubprogram(name: "cq_measure_si32", scope: !41, file: !41, line: 83, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DISubroutineType(types: !47)
!47 = !{!13, !13}
