; ModuleID = './w2g_mut_d1_no_invread.c'
source_filename = "./w2g_mut_d1_no_invread.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !26
    #dbg_value(i1 %1, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !27)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2, !dbg !28
    #dbg_value(i32 %2, !19, !DIExpression(), !27)
    #dbg_value(i32 0, !20, !DIExpression(), !27)
    #dbg_value(i32 0, !21, !DIExpression(), !29)
  br label %9, !dbg !30

3:                                                ; preds = %22
  %4 = tail call i32 @cq_measure_si32(i32 noundef %23) #2, !dbg !31
  %5 = add nsw i32 %4, %25, !dbg !32
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !33
  %7 = zext i1 %6 to i32, !dbg !33
  %8 = add nsw i32 %5, %7, !dbg !34
  ret i32 %8, !dbg !35

9:                                                ; preds = %0, %22
  %10 = phi i32 [ %2, %0 ], [ %23, %22 ]
  %11 = phi i32 [ 0, %0 ], [ %26, %22 ]
  %12 = phi i32 [ 0, %0 ], [ %25, %22 ]
    #dbg_value(i32 %10, !19, !DIExpression(), !27)
    #dbg_value(i32 %11, !21, !DIExpression(), !29)
    #dbg_value(i32 %12, !20, !DIExpression(), !27)
  %13 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !36
    #dbg_value(i32 %13, !23, !DIExpression(), !37)
  %14 = and i32 %13, 2, !dbg !38
  %15 = icmp eq i32 %14, 0, !dbg !38
  br i1 %15, label %18, label %16, !dbg !40

16:                                               ; preds = %9
  %17 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 2.000000e-01) #2, !dbg !41
    #dbg_value(i32 %17, !19, !DIExpression(), !27)
  br label %18, !dbg !42

18:                                               ; preds = %16, %9
  %19 = phi i32 [ %17, %16 ], [ %10, %9 ], !dbg !27
    #dbg_value(i32 %19, !19, !DIExpression(), !27)
  br i1 %1, label %20, label %22, !dbg !43

20:                                               ; preds = %18
  %21 = tail call i32 @cq_theta_si32(i32 noundef %19, double noundef 3.000000e-01) #2, !dbg !44
    #dbg_value(i32 %21, !19, !DIExpression(), !27)
  br label %22, !dbg !46

22:                                               ; preds = %20, %18
  %23 = phi i32 [ %21, %20 ], [ %19, %18 ], !dbg !37
    #dbg_value(i32 %23, !19, !DIExpression(), !27)
  %24 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !47
  %25 = add nsw i32 %24, %12, !dbg !48
    #dbg_value(i32 %25, !20, !DIExpression(), !27)
  %26 = add nuw nsw i32 %11, 1, !dbg !49
    #dbg_value(i32 %26, !21, !DIExpression(), !29)
  %27 = icmp eq i32 %11, 0, !dbg !50
  br i1 %27, label %9, label %3, !dbg !30, !llvm.loop !51
}

declare !dbg !55 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !60 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !63 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare !dbg !66 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !69 {
  %1 = tail call i32 @slice(), !dbg !70
  ret i32 %1, !dbg !71
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
!8 = !DIFile(filename: "w2g_mut_d1_no_invread.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "1560864546af672fb6bde3367825a276")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 8, type: !14, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2g_mut_d1_no_invread.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "1560864546af672fb6bde3367825a276")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21, !23}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 9, type: !10)
!19 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 10, type: !16)
!20 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 11, type: !16)
!21 = !DILocalVariable(name: "k", scope: !22, file: !13, line: 12, type: !16)
!22 = distinct !DILexicalBlock(scope: !12, file: !13, line: 12, column: 5)
!23 = !DILocalVariable(name: "u", scope: !24, file: !13, line: 13, type: !16)
!24 = distinct !DILexicalBlock(scope: !25, file: !13, line: 12, column: 36)
!25 = distinct !DILexicalBlock(scope: !22, file: !13, line: 12, column: 5)
!26 = !DILocation(line: 9, column: 14, scope: !12)
!27 = !DILocation(line: 0, scope: !12)
!28 = !DILocation(line: 10, column: 13, scope: !12)
!29 = !DILocation(line: 0, scope: !22)
!30 = !DILocation(line: 12, column: 5, scope: !22)
!31 = !DILocation(line: 18, column: 16, scope: !12)
!32 = !DILocation(line: 18, column: 14, scope: !12)
!33 = !DILocation(line: 18, column: 32, scope: !12)
!34 = !DILocation(line: 18, column: 30, scope: !12)
!35 = !DILocation(line: 18, column: 5, scope: !12)
!36 = !DILocation(line: 13, column: 17, scope: !24)
!37 = !DILocation(line: 0, scope: !24)
!38 = !DILocation(line: 14, column: 22, scope: !39)
!39 = distinct !DILexicalBlock(scope: !24, file: !13, line: 14, column: 13)
!40 = !DILocation(line: 14, column: 13, scope: !24)
!41 = !DILocation(line: 14, column: 31, scope: !39)
!42 = !DILocation(line: 14, column: 27, scope: !39)
!43 = !DILocation(line: 15, column: 13, scope: !24)
!44 = !DILocation(line: 15, column: 20, scope: !45)
!45 = distinct !DILexicalBlock(scope: !24, file: !13, line: 15, column: 13)
!46 = !DILocation(line: 15, column: 16, scope: !45)
!47 = !DILocation(line: 16, column: 14, scope: !24)
!48 = !DILocation(line: 16, column: 11, scope: !24)
!49 = !DILocation(line: 12, column: 31, scope: !25)
!50 = !DILocation(line: 12, column: 23, scope: !25)
!51 = distinct !{!51, !30, !52, !53, !54}
!52 = !DILocation(line: 17, column: 5, scope: !22)
!53 = !{!"llvm.loop.mustprogress"}
!54 = !{!"llvm.loop.unroll.disable"}
!55 = !DISubprogram(name: "cq_theta_i1", scope: !56, file: !56, line: 32, type: !57, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!56 = !DIFile(filename: "CQ_wx8g/include/CQ.h", directory: "/Users/sorenwilkening/Desktop", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!57 = !DISubroutineType(types: !58)
!58 = !{!10, !10, !59}
!59 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!60 = !DISubprogram(name: "cq_theta_si32", scope: !56, file: !56, line: 38, type: !61, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!61 = !DISubroutineType(types: !62)
!62 = !{!16, !16, !59}
!63 = !DISubprogram(name: "cq_measure_si32", scope: !56, file: !56, line: 83, type: !64, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!64 = !DISubroutineType(types: !65)
!65 = !{!16, !16}
!66 = !DISubprogram(name: "cq_measure_i1", scope: !56, file: !56, line: 77, type: !67, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!67 = !DISubroutineType(types: !68)
!68 = !{!10, !10}
!69 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 20, type: !14, scopeLine: 20, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!70 = !DILocation(line: 20, column: 25, scope: !69)
!71 = !DILocation(line: 20, column: 18, scope: !69)
