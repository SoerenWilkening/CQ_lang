; ModuleID = './w2e7_stateprep.c'
source_filename = "./w2e7_stateprep.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !25
    #dbg_value(i1 %1, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !26)
    #dbg_value(i32 0, !19, !DIExpression(), !26)
    #dbg_value(i32 0, !20, !DIExpression(), !27)
  br label %6, !dbg !28

2:                                                ; preds = %11
  %3 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !29
  %4 = zext i1 %3 to i32, !dbg !29
  %5 = add nsw i32 %14, %4, !dbg !30
  ret i32 %5, !dbg !31

6:                                                ; preds = %0, %11
  %7 = phi i32 [ 0, %0 ], [ %15, %11 ]
  %8 = phi i32 [ 0, %0 ], [ %14, %11 ]
    #dbg_value(i32 %7, !20, !DIExpression(), !27)
    #dbg_value(i32 %8, !19, !DIExpression(), !26)
    #dbg_value(i32 4, !22, !DIExpression(), !32)
  br i1 %1, label %9, label %11, !dbg !33

9:                                                ; preds = %6
  %10 = tail call i32 @cq_theta_si32(i32 noundef 4, double noundef 3.000000e-01) #2, !dbg !34
    #dbg_value(i32 %10, !22, !DIExpression(), !32)
  br label %11, !dbg !36

11:                                               ; preds = %9, %6
  %12 = phi i32 [ %10, %9 ], [ 4, %6 ], !dbg !32
    #dbg_value(i32 %12, !22, !DIExpression(), !32)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !37
  %14 = add nsw i32 %13, %8, !dbg !38
    #dbg_value(i32 %14, !19, !DIExpression(), !26)
  %15 = add nuw nsw i32 %7, 1, !dbg !39
    #dbg_value(i32 %15, !20, !DIExpression(), !27)
  %16 = icmp eq i32 %7, 0, !dbg !40
  br i1 %16, label %6, label %2, !dbg !28, !llvm.loop !41
}

declare !dbg !45 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !50 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !53 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare !dbg !56 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !59 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !60
    #dbg_value(i1 %1, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !62)
    #dbg_value(i32 0, !19, !DIExpression(), !62)
    #dbg_value(i32 0, !20, !DIExpression(), !63)
  br label %2, !dbg !64

2:                                                ; preds = %7, %0
  %3 = phi i32 [ 0, %0 ], [ %11, %7 ]
  %4 = phi i32 [ 0, %0 ], [ %10, %7 ]
    #dbg_value(i32 %3, !20, !DIExpression(), !63)
    #dbg_value(i32 %4, !19, !DIExpression(), !62)
    #dbg_value(i32 4, !22, !DIExpression(), !65)
  br i1 %1, label %5, label %7, !dbg !66

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef 4, double noundef 3.000000e-01) #2, !dbg !67
    #dbg_value(i32 %6, !22, !DIExpression(), !65)
  br label %7, !dbg !68

7:                                                ; preds = %5, %2
  %8 = phi i32 [ %6, %5 ], [ 4, %2 ], !dbg !65
    #dbg_value(i32 %8, !22, !DIExpression(), !65)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !69
  %10 = add nsw i32 %9, %4, !dbg !70
    #dbg_value(i32 %10, !19, !DIExpression(), !62)
  %11 = add nuw nsw i32 %3, 1, !dbg !71
    #dbg_value(i32 %11, !20, !DIExpression(), !63)
  %12 = icmp eq i32 %3, 0, !dbg !72
  br i1 %12, label %2, label %13, !dbg !64, !llvm.loop !73

13:                                               ; preds = %7
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !75
  %15 = zext i1 %14 to i32, !dbg !75
  %16 = add nsw i32 %10, %15, !dbg !76
  ret i32 %16, !dbg !77
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!11}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "w2e7_stateprep.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "99e18581ff273652aa16833bea8ef58c")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 4, type: !14, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2e7_stateprep.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "99e18581ff273652aa16833bea8ef58c")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !22}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 5, type: !10)
!19 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 6, type: !16)
!20 = !DILocalVariable(name: "k", scope: !21, file: !13, line: 7, type: !16)
!21 = distinct !DILexicalBlock(scope: !12, file: !13, line: 7, column: 5)
!22 = !DILocalVariable(name: "r", scope: !23, file: !13, line: 8, type: !16)
!23 = distinct !DILexicalBlock(scope: !24, file: !13, line: 7, column: 33)
!24 = distinct !DILexicalBlock(scope: !21, file: !13, line: 7, column: 5)
!25 = !DILocation(line: 5, column: 14, scope: !12)
!26 = !DILocation(line: 0, scope: !12)
!27 = !DILocation(line: 0, scope: !21)
!28 = !DILocation(line: 7, column: 5, scope: !21)
!29 = !DILocation(line: 12, column: 16, scope: !12)
!30 = !DILocation(line: 12, column: 14, scope: !12)
!31 = !DILocation(line: 12, column: 5, scope: !12)
!32 = !DILocation(line: 0, scope: !23)
!33 = !DILocation(line: 9, column: 13, scope: !23)
!34 = !DILocation(line: 9, column: 20, scope: !35)
!35 = distinct !DILexicalBlock(scope: !23, file: !13, line: 9, column: 13)
!36 = !DILocation(line: 9, column: 16, scope: !35)
!37 = !DILocation(line: 10, column: 14, scope: !23)
!38 = !DILocation(line: 10, column: 11, scope: !23)
!39 = !DILocation(line: 7, column: 28, scope: !24)
!40 = !DILocation(line: 7, column: 23, scope: !24)
!41 = distinct !{!41, !28, !42, !43, !44}
!42 = !DILocation(line: 11, column: 5, scope: !21)
!43 = !{!"llvm.loop.mustprogress"}
!44 = !{!"llvm.loop.unroll.disable"}
!45 = !DISubprogram(name: "cq_theta_i1", scope: !46, file: !46, line: 32, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DIFile(filename: "CQ_wx8g/include/CQ.h", directory: "/Users/sorenwilkening/Desktop", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!47 = !DISubroutineType(types: !48)
!48 = !{!10, !10, !49}
!49 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!50 = !DISubprogram(name: "cq_theta_si32", scope: !46, file: !46, line: 38, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DISubroutineType(types: !52)
!52 = !{!16, !16, !49}
!53 = !DISubprogram(name: "cq_measure_si32", scope: !46, file: !46, line: 83, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!54 = !DISubroutineType(types: !55)
!55 = !{!16, !16}
!56 = !DISubprogram(name: "cq_measure_i1", scope: !46, file: !46, line: 77, type: !57, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!57 = !DISubroutineType(types: !58)
!58 = !{!10, !10}
!59 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 14, type: !14, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!60 = !DILocation(line: 5, column: 14, scope: !12, inlinedAt: !61)
!61 = distinct !DILocation(line: 14, column: 25, scope: !59)
!62 = !DILocation(line: 0, scope: !12, inlinedAt: !61)
!63 = !DILocation(line: 0, scope: !21, inlinedAt: !61)
!64 = !DILocation(line: 7, column: 5, scope: !21, inlinedAt: !61)
!65 = !DILocation(line: 0, scope: !23, inlinedAt: !61)
!66 = !DILocation(line: 9, column: 13, scope: !23, inlinedAt: !61)
!67 = !DILocation(line: 9, column: 20, scope: !35, inlinedAt: !61)
!68 = !DILocation(line: 9, column: 16, scope: !35, inlinedAt: !61)
!69 = !DILocation(line: 10, column: 14, scope: !23, inlinedAt: !61)
!70 = !DILocation(line: 10, column: 11, scope: !23, inlinedAt: !61)
!71 = !DILocation(line: 7, column: 28, scope: !24, inlinedAt: !61)
!72 = !DILocation(line: 7, column: 23, scope: !24, inlinedAt: !61)
!73 = distinct !{!73, !64, !74, !43, !44}
!74 = !DILocation(line: 11, column: 5, scope: !21, inlinedAt: !61)
!75 = !DILocation(line: 12, column: 16, scope: !12, inlinedAt: !61)
!76 = !DILocation(line: 12, column: 14, scope: !12, inlinedAt: !61)
!77 = !DILocation(line: 14, column: 18, scope: !59)
