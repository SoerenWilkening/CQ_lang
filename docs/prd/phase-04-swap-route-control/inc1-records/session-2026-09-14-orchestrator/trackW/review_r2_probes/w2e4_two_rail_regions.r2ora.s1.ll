; ModuleID = './w2e4_two_rail_regions.c'
source_filename = "./w2e4_two_rail_regions.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !24
    #dbg_value(i1 %1, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !25)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #2, !dbg !26
    #dbg_value(i1 %2, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !25)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2, !dbg !27
    #dbg_value(i32 %3, !20, !DIExpression(), !25)
    #dbg_value(i32 0, !21, !DIExpression(), !25)
    #dbg_value(i32 0, !22, !DIExpression(), !28)
  br label %13, !dbg !29

4:                                                ; preds = %22
  %5 = tail call i32 @cq_measure_si32(i32 noundef %23) #2, !dbg !30
  %6 = add nsw i32 %5, 2, !dbg !31
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !32
  %8 = zext i1 %7 to i32, !dbg !32
  %9 = add nsw i32 %6, %8, !dbg !33
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #2, !dbg !34
  %11 = zext i1 %10 to i32, !dbg !34
  %12 = add nsw i32 %9, %11, !dbg !35
  ret i32 %12, !dbg !36

13:                                               ; preds = %0, %22
  %14 = phi i32 [ 0, %0 ], [ %24, %22 ]
  %15 = phi i32 [ %3, %0 ], [ %23, %22 ]
    #dbg_value(i32 %14, !22, !DIExpression(), !28)
    #dbg_value(i32 %14, !21, !DIExpression(), !25)
    #dbg_value(i32 %15, !20, !DIExpression(), !25)
  br i1 %1, label %16, label %18, !dbg !37

16:                                               ; preds = %13
  %17 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 3.000000e-01) #2, !dbg !40
    #dbg_value(i32 %17, !20, !DIExpression(), !25)
  br label %18, !dbg !42

18:                                               ; preds = %16, %13
  %19 = phi i32 [ %17, %16 ], [ %15, %13 ], !dbg !25
    #dbg_value(i32 %19, !20, !DIExpression(), !25)
  br i1 %2, label %20, label %22, !dbg !43

20:                                               ; preds = %18
  %21 = tail call i32 @cq_theta_si32(i32 noundef %19, double noundef 4.000000e-01) #2, !dbg !44
    #dbg_value(i32 %21, !20, !DIExpression(), !25)
  br label %22, !dbg !46

22:                                               ; preds = %20, %18
  %23 = phi i32 [ %21, %20 ], [ %19, %18 ], !dbg !47
    #dbg_value(i32 %23, !20, !DIExpression(), !25)
  %24 = add nuw nsw i32 %14, 1, !dbg !48
    #dbg_value(i32 %24, !21, !DIExpression(), !25)
    #dbg_value(i32 %24, !22, !DIExpression(), !28)
  %25 = icmp eq i32 %14, 0, !dbg !49
  br i1 %25, label %13, label %4, !dbg !29, !llvm.loop !50
}

declare !dbg !54 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !59 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !62 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare !dbg !65 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !68 {
  %1 = tail call i32 @slice(), !dbg !69
  ret i32 %1, !dbg !70
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
!8 = !DIFile(filename: "w2e4_two_rail_regions.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "fcc57ba423e9f280452dc55487268ec2")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2e4_two_rail_regions.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "fcc57ba423e9f280452dc55487268ec2")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21, !22}
!18 = !DILocalVariable(name: "b0", scope: !12, file: !13, line: 4, type: !10)
!19 = !DILocalVariable(name: "b1", scope: !12, file: !13, line: 5, type: !10)
!20 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 6, type: !16)
!21 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 7, type: !16)
!22 = !DILocalVariable(name: "k", scope: !23, file: !13, line: 8, type: !16)
!23 = distinct !DILexicalBlock(scope: !12, file: !13, line: 8, column: 5)
!24 = !DILocation(line: 4, column: 15, scope: !12)
!25 = !DILocation(line: 0, scope: !12)
!26 = !DILocation(line: 5, column: 15, scope: !12)
!27 = !DILocation(line: 6, column: 14, scope: !12)
!28 = !DILocation(line: 0, scope: !23)
!29 = !DILocation(line: 8, column: 5, scope: !23)
!30 = !DILocation(line: 13, column: 16, scope: !12)
!31 = !DILocation(line: 13, column: 14, scope: !12)
!32 = !DILocation(line: 13, column: 32, scope: !12)
!33 = !DILocation(line: 13, column: 30, scope: !12)
!34 = !DILocation(line: 13, column: 49, scope: !12)
!35 = !DILocation(line: 13, column: 47, scope: !12)
!36 = !DILocation(line: 13, column: 5, scope: !12)
!37 = !DILocation(line: 9, column: 13, scope: !38)
!38 = distinct !DILexicalBlock(scope: !39, file: !13, line: 8, column: 33)
!39 = distinct !DILexicalBlock(scope: !23, file: !13, line: 8, column: 5)
!40 = !DILocation(line: 9, column: 21, scope: !41)
!41 = distinct !DILexicalBlock(scope: !38, file: !13, line: 9, column: 13)
!42 = !DILocation(line: 9, column: 17, scope: !41)
!43 = !DILocation(line: 10, column: 13, scope: !38)
!44 = !DILocation(line: 10, column: 21, scope: !45)
!45 = distinct !DILexicalBlock(scope: !38, file: !13, line: 10, column: 13)
!46 = !DILocation(line: 10, column: 17, scope: !45)
!47 = !DILocation(line: 0, scope: !38)
!48 = !DILocation(line: 8, column: 28, scope: !39)
!49 = !DILocation(line: 8, column: 23, scope: !39)
!50 = distinct !{!50, !29, !51, !52, !53}
!51 = !DILocation(line: 12, column: 5, scope: !23)
!52 = !{!"llvm.loop.mustprogress"}
!53 = !{!"llvm.loop.unroll.disable"}
!54 = !DISubprogram(name: "cq_theta_i1", scope: !55, file: !55, line: 32, type: !56, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = !DIFile(filename: "CQ_wx8g/include/CQ.h", directory: "/Users/sorenwilkening/Desktop", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!56 = !DISubroutineType(types: !57)
!57 = !{!10, !10, !58}
!58 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!59 = !DISubprogram(name: "cq_theta_si32", scope: !55, file: !55, line: 38, type: !60, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!60 = !DISubroutineType(types: !61)
!61 = !{!16, !16, !58}
!62 = !DISubprogram(name: "cq_measure_si32", scope: !55, file: !55, line: 83, type: !63, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!63 = !DISubroutineType(types: !64)
!64 = !{!16, !16}
!65 = !DISubprogram(name: "cq_measure_i1", scope: !55, file: !55, line: 77, type: !66, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!66 = !DISubroutineType(types: !67)
!67 = !{!10, !10}
!68 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 15, type: !14, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!69 = !DILocation(line: 15, column: 25, scope: !68)
!70 = !DILocation(line: 15, column: 18, scope: !68)
