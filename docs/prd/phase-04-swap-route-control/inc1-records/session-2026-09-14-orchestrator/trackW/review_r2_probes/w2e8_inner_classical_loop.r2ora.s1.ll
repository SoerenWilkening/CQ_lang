; ModuleID = './w2e8_inner_classical_loop.c'
source_filename = "./w2e8_inner_classical_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !27
    #dbg_value(i1 %1, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !28)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2, !dbg !29
    #dbg_value(i32 %2, !19, !DIExpression(), !28)
    #dbg_value(i32 0, !20, !DIExpression(), !28)
    #dbg_value(i32 0, !21, !DIExpression(), !30)
  br label %9, !dbg !31

3:                                                ; preds = %14
  %4 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !32
  %5 = add nsw i32 %4, 6, !dbg !33
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !34
  %7 = zext i1 %6 to i32, !dbg !34
  %8 = add nsw i32 %5, %7, !dbg !35
  ret i32 %8, !dbg !36

9:                                                ; preds = %0, %14
  %10 = phi i32 [ 0, %0 ], [ %16, %14 ]
  %11 = phi i32 [ %2, %0 ], [ %15, %14 ]
    #dbg_value(i32 %10, !21, !DIExpression(), !30)
    #dbg_value(i32 poison, !20, !DIExpression(), !28)
    #dbg_value(i32 %11, !19, !DIExpression(), !28)
  br i1 %1, label %12, label %14, !dbg !37

12:                                               ; preds = %9
  %13 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 3.000000e-01) #2, !dbg !38
    #dbg_value(i32 %13, !19, !DIExpression(), !28)
  br label %14, !dbg !40

14:                                               ; preds = %9, %12
  %15 = phi i32 [ %13, %12 ], [ %11, %9 ], !dbg !28
    #dbg_value(i32 %15, !19, !DIExpression(), !28)
    #dbg_value(i32 0, !23, !DIExpression(), !41)
    #dbg_value(i32 poison, !20, !DIExpression(), !28)
    #dbg_value(i32 undef, !23, !DIExpression(), !41)
    #dbg_value(i32 poison, !20, !DIExpression(), !28)
  %16 = add nuw nsw i32 %10, 1, !dbg !42
    #dbg_value(i32 %16, !21, !DIExpression(), !30)
    #dbg_value(i32 poison, !20, !DIExpression(DW_OP_plus_uconst, 3, DW_OP_stack_value), !28)
    #dbg_value(i32 %15, !19, !DIExpression(), !28)
  %17 = icmp eq i32 %10, 0, !dbg !43
  br i1 %17, label %9, label %3, !dbg !31, !llvm.loop !44
}

declare !dbg !48 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !53 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !56 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare !dbg !59 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !62 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !63
    #dbg_value(i1 %1, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !65)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2, !dbg !66
    #dbg_value(i32 %2, !19, !DIExpression(), !65)
    #dbg_value(i32 0, !20, !DIExpression(), !65)
    #dbg_value(i32 0, !21, !DIExpression(), !67)
  br label %3, !dbg !68

3:                                                ; preds = %8, %0
  %4 = phi i32 [ 0, %0 ], [ %10, %8 ]
  %5 = phi i32 [ %2, %0 ], [ %9, %8 ]
    #dbg_value(i32 %4, !21, !DIExpression(), !67)
    #dbg_value(i32 poison, !20, !DIExpression(), !65)
    #dbg_value(i32 %5, !19, !DIExpression(), !65)
  br i1 %1, label %6, label %8, !dbg !69

6:                                                ; preds = %3
  %7 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 3.000000e-01) #2, !dbg !70
    #dbg_value(i32 %7, !19, !DIExpression(), !65)
  br label %8, !dbg !71

8:                                                ; preds = %6, %3
  %9 = phi i32 [ %7, %6 ], [ %5, %3 ], !dbg !65
    #dbg_value(i32 %9, !19, !DIExpression(), !65)
    #dbg_value(i32 poison, !20, !DIExpression(), !65)
    #dbg_value(i32 poison, !20, !DIExpression(), !65)
  %10 = add nuw nsw i32 %4, 1, !dbg !72
    #dbg_value(i32 %10, !21, !DIExpression(), !67)
    #dbg_value(i32 poison, !20, !DIExpression(DW_OP_plus_uconst, 3, DW_OP_stack_value), !65)
    #dbg_value(i32 %9, !19, !DIExpression(), !65)
  %11 = icmp eq i32 %4, 0, !dbg !73
  br i1 %11, label %3, label %12, !dbg !68, !llvm.loop !74

12:                                               ; preds = %8
  %13 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !76
  %14 = add nsw i32 %13, 6, !dbg !77
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !78
  %16 = zext i1 %15 to i32, !dbg !78
  %17 = add nsw i32 %14, %16, !dbg !79
  ret i32 %17, !dbg !80
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
!8 = !DIFile(filename: "w2e8_inner_classical_loop.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "6288ad51de85219b6fab2863d08dfb7a")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2e8_inner_classical_loop.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "6288ad51de85219b6fab2863d08dfb7a")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21, !23}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 4, type: !10)
!19 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 5, type: !16)
!20 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 6, type: !16)
!21 = !DILocalVariable(name: "k", scope: !22, file: !13, line: 7, type: !16)
!22 = distinct !DILexicalBlock(scope: !12, file: !13, line: 7, column: 5)
!23 = !DILocalVariable(name: "j", scope: !24, file: !13, line: 9, type: !16)
!24 = distinct !DILexicalBlock(scope: !25, file: !13, line: 9, column: 9)
!25 = distinct !DILexicalBlock(scope: !26, file: !13, line: 7, column: 33)
!26 = distinct !DILexicalBlock(scope: !22, file: !13, line: 7, column: 5)
!27 = !DILocation(line: 4, column: 14, scope: !12)
!28 = !DILocation(line: 0, scope: !12)
!29 = !DILocation(line: 5, column: 14, scope: !12)
!30 = !DILocation(line: 0, scope: !22)
!31 = !DILocation(line: 7, column: 5, scope: !22)
!32 = !DILocation(line: 11, column: 16, scope: !12)
!33 = !DILocation(line: 11, column: 14, scope: !12)
!34 = !DILocation(line: 11, column: 32, scope: !12)
!35 = !DILocation(line: 11, column: 30, scope: !12)
!36 = !DILocation(line: 11, column: 5, scope: !12)
!37 = !DILocation(line: 8, column: 13, scope: !25)
!38 = !DILocation(line: 8, column: 20, scope: !39)
!39 = distinct !DILexicalBlock(scope: !25, file: !13, line: 8, column: 13)
!40 = !DILocation(line: 8, column: 16, scope: !39)
!41 = !DILocation(line: 0, scope: !24)
!42 = !DILocation(line: 7, column: 28, scope: !26)
!43 = !DILocation(line: 7, column: 23, scope: !26)
!44 = distinct !{!44, !31, !45, !46, !47}
!45 = !DILocation(line: 10, column: 5, scope: !22)
!46 = !{!"llvm.loop.mustprogress"}
!47 = !{!"llvm.loop.unroll.disable"}
!48 = !DISubprogram(name: "cq_theta_i1", scope: !49, file: !49, line: 32, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!49 = !DIFile(filename: "CQ_wx8g/include/CQ.h", directory: "/Users/sorenwilkening/Desktop", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!50 = !DISubroutineType(types: !51)
!51 = !{!10, !10, !52}
!52 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!53 = !DISubprogram(name: "cq_theta_si32", scope: !49, file: !49, line: 38, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!54 = !DISubroutineType(types: !55)
!55 = !{!16, !16, !52}
!56 = !DISubprogram(name: "cq_measure_si32", scope: !49, file: !49, line: 83, type: !57, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!57 = !DISubroutineType(types: !58)
!58 = !{!16, !16}
!59 = !DISubprogram(name: "cq_measure_i1", scope: !49, file: !49, line: 77, type: !60, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!60 = !DISubroutineType(types: !61)
!61 = !{!10, !10}
!62 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 13, type: !14, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!63 = !DILocation(line: 4, column: 14, scope: !12, inlinedAt: !64)
!64 = distinct !DILocation(line: 13, column: 25, scope: !62)
!65 = !DILocation(line: 0, scope: !12, inlinedAt: !64)
!66 = !DILocation(line: 5, column: 14, scope: !12, inlinedAt: !64)
!67 = !DILocation(line: 0, scope: !22, inlinedAt: !64)
!68 = !DILocation(line: 7, column: 5, scope: !22, inlinedAt: !64)
!69 = !DILocation(line: 8, column: 13, scope: !25, inlinedAt: !64)
!70 = !DILocation(line: 8, column: 20, scope: !39, inlinedAt: !64)
!71 = !DILocation(line: 8, column: 16, scope: !39, inlinedAt: !64)
!72 = !DILocation(line: 7, column: 28, scope: !26, inlinedAt: !64)
!73 = !DILocation(line: 7, column: 23, scope: !26, inlinedAt: !64)
!74 = distinct !{!74, !68, !75, !46, !47}
!75 = !DILocation(line: 10, column: 5, scope: !22, inlinedAt: !64)
!76 = !DILocation(line: 11, column: 16, scope: !12, inlinedAt: !64)
!77 = !DILocation(line: 11, column: 14, scope: !12, inlinedAt: !64)
!78 = !DILocation(line: 11, column: 32, scope: !12, inlinedAt: !64)
!79 = !DILocation(line: 11, column: 30, scope: !12, inlinedAt: !64)
!80 = !DILocation(line: 13, column: 18, scope: !62)
