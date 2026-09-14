; ModuleID = './w2e5_negated.c'
source_filename = "./w2e5_negated.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !23
    #dbg_value(i1 %1, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !24)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2, !dbg !25
    #dbg_value(i32 %2, !19, !DIExpression(), !24)
    #dbg_value(i32 0, !20, !DIExpression(), !24)
    #dbg_value(i32 0, !21, !DIExpression(), !26)
  br label %9, !dbg !27

3:                                                ; preds = %14
  %4 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !28
  %5 = add nsw i32 %4, 2, !dbg !29
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !30
  %7 = zext i1 %6 to i32, !dbg !30
  %8 = add nsw i32 %5, %7, !dbg !31
  ret i32 %8, !dbg !32

9:                                                ; preds = %0, %14
  %10 = phi i32 [ 0, %0 ], [ %16, %14 ]
  %11 = phi i32 [ %2, %0 ], [ %15, %14 ]
    #dbg_value(i32 %10, !21, !DIExpression(), !26)
    #dbg_value(i32 %10, !20, !DIExpression(), !24)
    #dbg_value(i32 %11, !19, !DIExpression(), !24)
  br i1 %1, label %14, label %12, !dbg !33

12:                                               ; preds = %9
  %13 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 3.000000e-01) #2, !dbg !36
    #dbg_value(i32 %13, !19, !DIExpression(), !24)
  br label %14, !dbg !38

14:                                               ; preds = %12, %9
  %15 = phi i32 [ %11, %9 ], [ %13, %12 ], !dbg !24
    #dbg_value(i32 %15, !19, !DIExpression(), !24)
  %16 = add nuw nsw i32 %10, 1, !dbg !39
    #dbg_value(i32 %16, !20, !DIExpression(), !24)
    #dbg_value(i32 %16, !21, !DIExpression(), !26)
  %17 = icmp eq i32 %10, 0, !dbg !40
  br i1 %17, label %9, label %3, !dbg !27, !llvm.loop !41
}

declare !dbg !45 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !50 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !53 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare !dbg !56 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !59 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !60
    #dbg_value(i1 %1, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !62)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2, !dbg !63
    #dbg_value(i32 %2, !19, !DIExpression(), !62)
    #dbg_value(i32 0, !20, !DIExpression(), !62)
    #dbg_value(i32 0, !21, !DIExpression(), !64)
  br label %3, !dbg !65

3:                                                ; preds = %8, %0
  %4 = phi i32 [ 0, %0 ], [ %10, %8 ]
  %5 = phi i32 [ %2, %0 ], [ %9, %8 ]
    #dbg_value(i32 %4, !21, !DIExpression(), !64)
    #dbg_value(i32 %4, !20, !DIExpression(), !62)
    #dbg_value(i32 %5, !19, !DIExpression(), !62)
  br i1 %1, label %8, label %6, !dbg !66

6:                                                ; preds = %3
  %7 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 3.000000e-01) #2, !dbg !67
    #dbg_value(i32 %7, !19, !DIExpression(), !62)
  br label %8, !dbg !68

8:                                                ; preds = %6, %3
  %9 = phi i32 [ %5, %3 ], [ %7, %6 ], !dbg !62
    #dbg_value(i32 %9, !19, !DIExpression(), !62)
  %10 = add nuw nsw i32 %4, 1, !dbg !69
    #dbg_value(i32 %10, !20, !DIExpression(), !62)
    #dbg_value(i32 %10, !21, !DIExpression(), !64)
  %11 = icmp eq i32 %4, 0, !dbg !70
  br i1 %11, label %3, label %12, !dbg !65, !llvm.loop !71

12:                                               ; preds = %8
  %13 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !73
  %14 = add nsw i32 %13, 2, !dbg !74
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !75
  %16 = zext i1 %15 to i32, !dbg !75
  %17 = add nsw i32 %14, %16, !dbg !76
  ret i32 %17, !dbg !77
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
!8 = !DIFile(filename: "w2e5_negated.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "4d3c6da5855058ca34cfa54c205e7c5c")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2e5_negated.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "4d3c6da5855058ca34cfa54c205e7c5c")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 4, type: !10)
!19 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 5, type: !16)
!20 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 6, type: !16)
!21 = !DILocalVariable(name: "k", scope: !22, file: !13, line: 7, type: !16)
!22 = distinct !DILexicalBlock(scope: !12, file: !13, line: 7, column: 5)
!23 = !DILocation(line: 4, column: 14, scope: !12)
!24 = !DILocation(line: 0, scope: !12)
!25 = !DILocation(line: 5, column: 14, scope: !12)
!26 = !DILocation(line: 0, scope: !22)
!27 = !DILocation(line: 7, column: 5, scope: !22)
!28 = !DILocation(line: 11, column: 16, scope: !12)
!29 = !DILocation(line: 11, column: 14, scope: !12)
!30 = !DILocation(line: 11, column: 32, scope: !12)
!31 = !DILocation(line: 11, column: 30, scope: !12)
!32 = !DILocation(line: 11, column: 5, scope: !12)
!33 = !DILocation(line: 8, column: 13, scope: !34)
!34 = distinct !DILexicalBlock(scope: !35, file: !13, line: 7, column: 33)
!35 = distinct !DILexicalBlock(scope: !22, file: !13, line: 7, column: 5)
!36 = !DILocation(line: 8, column: 21, scope: !37)
!37 = distinct !DILexicalBlock(scope: !34, file: !13, line: 8, column: 13)
!38 = !DILocation(line: 8, column: 17, scope: !37)
!39 = !DILocation(line: 7, column: 28, scope: !35)
!40 = !DILocation(line: 7, column: 23, scope: !35)
!41 = distinct !{!41, !27, !42, !43, !44}
!42 = !DILocation(line: 10, column: 5, scope: !22)
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
!59 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 13, type: !14, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!60 = !DILocation(line: 4, column: 14, scope: !12, inlinedAt: !61)
!61 = distinct !DILocation(line: 13, column: 25, scope: !59)
!62 = !DILocation(line: 0, scope: !12, inlinedAt: !61)
!63 = !DILocation(line: 5, column: 14, scope: !12, inlinedAt: !61)
!64 = !DILocation(line: 0, scope: !22, inlinedAt: !61)
!65 = !DILocation(line: 7, column: 5, scope: !22, inlinedAt: !61)
!66 = !DILocation(line: 8, column: 13, scope: !34, inlinedAt: !61)
!67 = !DILocation(line: 8, column: 21, scope: !37, inlinedAt: !61)
!68 = !DILocation(line: 8, column: 17, scope: !37, inlinedAt: !61)
!69 = !DILocation(line: 7, column: 28, scope: !35, inlinedAt: !61)
!70 = !DILocation(line: 7, column: 23, scope: !35, inlinedAt: !61)
!71 = distinct !{!71, !65, !72, !43, !44}
!72 = !DILocation(line: 10, column: 5, scope: !22, inlinedAt: !61)
!73 = !DILocation(line: 11, column: 16, scope: !12, inlinedAt: !61)
!74 = !DILocation(line: 11, column: 14, scope: !12, inlinedAt: !61)
!75 = !DILocation(line: 11, column: 32, scope: !12, inlinedAt: !61)
!76 = !DILocation(line: 11, column: 30, scope: !12, inlinedAt: !61)
!77 = !DILocation(line: 13, column: 18, scope: !59)
