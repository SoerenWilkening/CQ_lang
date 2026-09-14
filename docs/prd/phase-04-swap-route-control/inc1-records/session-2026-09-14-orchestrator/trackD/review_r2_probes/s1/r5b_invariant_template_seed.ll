; ModuleID = 'src/r5b_invariant_template_seed.c'
source_filename = "src/r5b_invariant_template_seed.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !24)
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2, !dbg !25
    #dbg_value(i32 %2, !16, !DIExpression(), !24)
  %3 = and i32 %2, 1, !dbg !26
    #dbg_value(i32 %3, !17, !DIExpression(), !24)
    #dbg_value(i32 0, !18, !DIExpression(), !24)
    #dbg_value(i32 0, !19, !DIExpression(), !27)
  br label %5, !dbg !28

4:                                                ; preds = %5
  ret i32 %10, !dbg !29

5:                                                ; preds = %1, %5
  %6 = phi i32 [ 0, %1 ], [ %10, %5 ]
  %7 = phi i32 [ 0, %1 ], [ %11, %5 ]
    #dbg_value(i32 %6, !18, !DIExpression(), !24)
    #dbg_value(i32 %7, !19, !DIExpression(), !27)
  %8 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.000000e-01) #2, !dbg !30
    #dbg_value(i32 %8, !21, !DIExpression(), !31)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !32
  %10 = add nsw i32 %9, %6, !dbg !33
    #dbg_value(i32 %10, !18, !DIExpression(), !24)
  %11 = add nuw nsw i32 %7, 1, !dbg !34
    #dbg_value(i32 %11, !19, !DIExpression(), !27)
  %12 = icmp eq i32 %11, 3, !dbg !35
  br i1 %12, label %4, label %5, !dbg !28, !llvm.loop !36
}

declare !dbg !40 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !45 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !46 {
    #dbg_value(i32 3, !15, !DIExpression(), !49)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #2, !dbg !51
    #dbg_value(i32 %1, !16, !DIExpression(), !49)
  %2 = and i32 %1, 1, !dbg !52
    #dbg_value(i32 %2, !17, !DIExpression(), !49)
    #dbg_value(i32 0, !18, !DIExpression(), !49)
    #dbg_value(i32 0, !19, !DIExpression(), !53)
  br label %3, !dbg !54

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %8, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %9, %3 ]
    #dbg_value(i32 %4, !18, !DIExpression(), !49)
    #dbg_value(i32 %5, !19, !DIExpression(), !53)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 1.000000e-01) #2, !dbg !55
    #dbg_value(i32 %6, !21, !DIExpression(), !56)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !57
  %8 = add nsw i32 %7, %4, !dbg !58
    #dbg_value(i32 %8, !18, !DIExpression(), !49)
  %9 = add nuw nsw i32 %5, 1, !dbg !59
    #dbg_value(i32 %9, !19, !DIExpression(), !53)
  %10 = icmp eq i32 %9, 3, !dbg !60
  br i1 %10, label %11, label %3, !dbg !54, !llvm.loop !61

11:                                               ; preds = %3
  ret i32 %8, !dbg !63
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
!8 = !DIFile(filename: "src/r5b_invariant_template_seed.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "a9c7a3db807f062dc6de69d9025048e1")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !19, !21}
!15 = !DILocalVariable(name: "u", arg: 1, scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "t", scope: !10, file: !8, line: 3, type: !13)
!18 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!19 = !DILocalVariable(name: "i", scope: !20, file: !8, line: 4, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!21 = !DILocalVariable(name: "b", scope: !22, file: !8, line: 4, type: !13)
!22 = distinct !DILexicalBlock(scope: !23, file: !8, line: 4, column: 23)
!23 = distinct !DILexicalBlock(scope: !20, file: !8, line: 4, column: 3)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 3, column: 25, scope: !10)
!26 = !DILocation(line: 3, column: 49, scope: !10)
!27 = !DILocation(line: 0, scope: !20)
!28 = !DILocation(line: 4, column: 3, scope: !20)
!29 = !DILocation(line: 4, column: 68, scope: !10)
!30 = !DILocation(line: 4, column: 31, scope: !22)
!31 = !DILocation(line: 0, scope: !22)
!32 = !DILocation(line: 4, column: 51, scope: !22)
!33 = !DILocation(line: 4, column: 49, scope: !22)
!34 = !DILocation(line: 4, column: 20, scope: !23)
!35 = !DILocation(line: 4, column: 16, scope: !23)
!36 = distinct !{!36, !28, !37, !38, !39}
!37 = !DILocation(line: 4, column: 66, scope: !20)
!38 = !{!"llvm.loop.mustprogress"}
!39 = !{!"llvm.loop.unroll.disable"}
!40 = !DISubprogram(name: "cq_theta_si32", scope: !41, file: !41, line: 38, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!42 = !DISubroutineType(types: !43)
!43 = !{!13, !13, !44}
!44 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!45 = !DISubprogram(name: "cq_measure_si32", scope: !41, file: !41, line: 83, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !47, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!47 = !DISubroutineType(types: !48)
!48 = !{!13}
!49 = !DILocation(line: 0, scope: !10, inlinedAt: !50)
!50 = distinct !DILocation(line: 5, column: 24, scope: !46)
!51 = !DILocation(line: 3, column: 25, scope: !10, inlinedAt: !50)
!52 = !DILocation(line: 3, column: 49, scope: !10, inlinedAt: !50)
!53 = !DILocation(line: 0, scope: !20, inlinedAt: !50)
!54 = !DILocation(line: 4, column: 3, scope: !20, inlinedAt: !50)
!55 = !DILocation(line: 4, column: 31, scope: !22, inlinedAt: !50)
!56 = !DILocation(line: 0, scope: !22, inlinedAt: !50)
!57 = !DILocation(line: 4, column: 51, scope: !22, inlinedAt: !50)
!58 = !DILocation(line: 4, column: 49, scope: !22, inlinedAt: !50)
!59 = !DILocation(line: 4, column: 20, scope: !23, inlinedAt: !50)
!60 = !DILocation(line: 4, column: 16, scope: !23, inlinedAt: !50)
!61 = distinct !{!61, !54, !62, !38, !39}
!62 = !DILocation(line: 4, column: 66, scope: !20, inlinedAt: !50)
!63 = !DILocation(line: 5, column: 17, scope: !46)
