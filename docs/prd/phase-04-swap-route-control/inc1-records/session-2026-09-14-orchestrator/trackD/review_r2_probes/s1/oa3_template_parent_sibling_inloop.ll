; ModuleID = 'src/oa3_template_parent_sibling_inloop.c'
source_filename = "src/oa3_template_parent_sibling_inloop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !24
    #dbg_value(i32 %1, !15, !DIExpression(), !25)
  %2 = and i32 %1, 1, !dbg !26
    #dbg_value(i32 %2, !16, !DIExpression(), !25)
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 4.000000e-01) #2, !dbg !27
    #dbg_value(i32 %3, !17, !DIExpression(), !25)
    #dbg_value(i32 0, !18, !DIExpression(), !25)
    #dbg_value(i32 0, !19, !DIExpression(), !28)
  br label %5, !dbg !29

4:                                                ; preds = %5
  ret i32 %14, !dbg !30

5:                                                ; preds = %0, %5
  %6 = phi i32 [ %3, %0 ], [ %9, %5 ]
  %7 = phi i32 [ 0, %0 ], [ %15, %5 ]
  %8 = phi i32 [ 0, %0 ], [ %14, %5 ]
    #dbg_value(i32 %6, !17, !DIExpression(), !25)
    #dbg_value(i32 %7, !19, !DIExpression(), !28)
    #dbg_value(i32 %8, !18, !DIExpression(), !25)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 1.000000e-01) #2, !dbg !31
    #dbg_value(i32 %9, !17, !DIExpression(), !25)
  %10 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #2, !dbg !32
    #dbg_value(i32 %10, !21, !DIExpression(), !33)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !34
  %12 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !35
  %13 = add i32 %11, %8, !dbg !36
  %14 = add i32 %13, %12, !dbg !37
    #dbg_value(i32 %14, !18, !DIExpression(), !25)
  %15 = add nuw nsw i32 %7, 1, !dbg !38
    #dbg_value(i32 %15, !19, !DIExpression(), !28)
  %16 = icmp eq i32 %15, 3, !dbg !39
  br i1 %16, label %4, label %5, !dbg !29, !llvm.loop !40
}

declare !dbg !44 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !49 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/oa3_template_parent_sibling_inloop.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "3f54e57b7cb0f518061280c1731952ef")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !19, !21}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "t", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "u", scope: !10, file: !8, line: 4, type: !13)
!18 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!19 = !DILocalVariable(name: "i", scope: !20, file: !8, line: 5, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 3)
!21 = !DILocalVariable(name: "w", scope: !22, file: !8, line: 5, type: !13)
!22 = distinct !DILexicalBlock(scope: !23, file: !8, line: 5, column: 23)
!23 = distinct !DILexicalBlock(scope: !20, file: !8, line: 5, column: 3)
!24 = !DILocation(line: 4, column: 23, scope: !10)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 4, column: 47, scope: !10)
!27 = !DILocation(line: 4, column: 57, scope: !10)
!28 = !DILocation(line: 0, scope: !20)
!29 = !DILocation(line: 5, column: 3, scope: !20)
!30 = !DILocation(line: 6, column: 3, scope: !10)
!31 = !DILocation(line: 5, column: 27, scope: !22)
!32 = !DILocation(line: 5, column: 50, scope: !22)
!33 = !DILocation(line: 0, scope: !22)
!34 = !DILocation(line: 5, column: 70, scope: !22)
!35 = !DILocation(line: 5, column: 84, scope: !22)
!36 = !DILocation(line: 5, column: 83, scope: !22)
!37 = !DILocation(line: 5, column: 68, scope: !22)
!38 = !DILocation(line: 5, column: 20, scope: !23)
!39 = !DILocation(line: 5, column: 16, scope: !23)
!40 = distinct !{!40, !29, !41, !42, !43}
!41 = !DILocation(line: 5, column: 99, scope: !20)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = !DISubprogram(name: "cq_theta_si32", scope: !45, file: !45, line: 38, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!46 = !DISubroutineType(types: !47)
!47 = !{!13, !13, !48}
!48 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!49 = !DISubprogram(name: "cq_measure_si32", scope: !45, file: !45, line: 83, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!50 = !DISubroutineType(types: !51)
!51 = !{!13, !13}
