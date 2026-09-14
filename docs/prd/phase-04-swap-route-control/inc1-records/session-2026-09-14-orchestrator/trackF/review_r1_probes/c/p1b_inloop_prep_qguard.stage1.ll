; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p1b_inloop_prep_qguard.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p1b_inloop_prep_qguard.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !25
  %2 = icmp ne i32 %1, 0, !dbg !25
    #dbg_value(i1 %2, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !26)
    #dbg_value(i8 0, !18, !DIExpression(), !26)
    #dbg_value(i32 0, !19, !DIExpression(), !26)
    #dbg_value(i32 0, !20, !DIExpression(), !27)
    #dbg_value(i8 poison, !18, !DIExpression(), !26)
  br label %7, !dbg !28

3:                                                ; preds = %13
  %4 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #2, !dbg !29
  %5 = zext i1 %4 to i32, !dbg !29
  %6 = add nuw nsw i32 %17, %5, !dbg !30
  ret i32 %6, !dbg !31

7:                                                ; preds = %0, %13
  %8 = phi i32 [ 0, %0 ], [ %18, %13 ]
  %9 = phi i32 [ 0, %0 ], [ %17, %13 ]
  %10 = phi i1 [ false, %0 ], [ %14, %13 ]
    #dbg_value(i32 %8, !20, !DIExpression(), !27)
    #dbg_value(i32 %9, !19, !DIExpression(), !26)
    #dbg_value(i8 0, !22, !DIExpression(), !32)
  br i1 %2, label %11, label %13, !dbg !33

11:                                               ; preds = %7
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !34
    #dbg_value(i1 %12, !22, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !32)
  br label %13, !dbg !37

13:                                               ; preds = %11, %7
  %14 = phi i1 [ %12, %11 ], [ false, %7 ], !dbg !32
    #dbg_value(i8 poison, !22, !DIExpression(), !32)
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10) #2, !dbg !38
  %16 = zext i1 %15 to i32, !dbg !38
  %17 = add nuw nsw i32 %9, %16, !dbg !39
    #dbg_value(i32 %17, !19, !DIExpression(), !26)
    #dbg_value(i1 %14, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !26)
  %18 = add nuw nsw i32 %8, 1, !dbg !40
    #dbg_value(i32 %18, !20, !DIExpression(), !27)
    #dbg_value(i8 poison, !18, !DIExpression(), !26)
  %19 = icmp eq i32 %18, 3, !dbg !41
  br i1 %19, label %3, label %7, !dbg !28, !llvm.loop !42
}

declare !dbg !46 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !51 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !54 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p1b_inloop_prep_qguard.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "6186c4636f9c1f938bf7cbbb4d45fb8e")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 5, type: !12, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p1b_inloop_prep_qguard.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "6186c4636f9c1f938bf7cbbb4d45fb8e")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !18, !19, !20, !22}
!16 = !DILocalVariable(name: "q", scope: !10, file: !11, line: 6, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "v", scope: !10, file: !11, line: 7, type: !17)
!19 = !DILocalVariable(name: "s", scope: !10, file: !11, line: 8, type: !14)
!20 = !DILocalVariable(name: "i", scope: !21, file: !11, line: 9, type: !14)
!21 = distinct !DILexicalBlock(scope: !10, file: !11, line: 9, column: 5)
!22 = !DILocalVariable(name: "b", scope: !23, file: !11, line: 10, type: !17)
!23 = distinct !DILexicalBlock(scope: !24, file: !11, line: 9, column: 33)
!24 = distinct !DILexicalBlock(scope: !21, file: !11, line: 9, column: 5)
!25 = !DILocation(line: 6, column: 14, scope: !10)
!26 = !DILocation(line: 0, scope: !10)
!27 = !DILocation(line: 0, scope: !21)
!28 = !DILocation(line: 9, column: 5, scope: !21)
!29 = !DILocation(line: 15, column: 16, scope: !10)
!30 = !DILocation(line: 15, column: 14, scope: !10)
!31 = !DILocation(line: 15, column: 5, scope: !10)
!32 = !DILocation(line: 0, scope: !23)
!33 = !DILocation(line: 11, column: 13, scope: !23)
!34 = !DILocation(line: 11, column: 22, scope: !35)
!35 = distinct !DILexicalBlock(scope: !36, file: !11, line: 11, column: 16)
!36 = distinct !DILexicalBlock(scope: !23, file: !11, line: 11, column: 13)
!37 = !DILocation(line: 11, column: 40, scope: !35)
!38 = !DILocation(line: 12, column: 14, scope: !23)
!39 = !DILocation(line: 12, column: 11, scope: !23)
!40 = !DILocation(line: 9, column: 29, scope: !24)
!41 = !DILocation(line: 9, column: 23, scope: !24)
!42 = distinct !{!42, !28, !43, !44, !45}
!43 = !DILocation(line: 14, column: 5, scope: !21)
!44 = !{!"llvm.loop.mustprogress"}
!45 = !{!"llvm.loop.unroll.disable"}
!46 = !DISubprogram(name: "cq_theta_si32", scope: !47, file: !47, line: 38, type: !48, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!48 = !DISubroutineType(types: !49)
!49 = !{!14, !14, !50}
!50 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!51 = !DISubprogram(name: "cq_theta_i1", scope: !47, file: !47, line: 32, type: !52, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!52 = !DISubroutineType(types: !53)
!53 = !{!17, !17, !50}
!54 = !DISubprogram(name: "cq_measure_i1", scope: !47, file: !47, line: 77, type: !55, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = !DISubroutineType(types: !56)
!56 = !{!17, !17}
