; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r04_measure_tree.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r04_measure_tree.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #2, !dbg !21
    #dbg_value(i32 %1, !17, !DIExpression(), !22)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !23
    #dbg_value(i1 %2, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i8 0, !19, !DIExpression(), !22)
  br i1 %2, label %3, label %5, !dbg !24

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !25
    #dbg_value(i1 %4, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
  br label %5, !dbg !28

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ false, %0 ], !dbg !22
    #dbg_value(i8 poison, !19, !DIExpression(), !22)
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !29
    #dbg_value(i1 %7, !20, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_stack_value), !22)
  %8 = icmp sgt i32 %1, 3
  %9 = select i1 %6, i1 %8, i1 false, !dbg !30
  br i1 %9, label %10, label %11, !dbg !30

10:                                               ; preds = %5
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !32
  br label %11, !dbg !32

11:                                               ; preds = %10, %5
  %12 = zext i1 %7 to i32, !dbg !29
    #dbg_value(i32 %12, !20, !DIExpression(), !22)
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #2, !dbg !33
  %14 = zext i1 %13 to i32, !dbg !33
  %15 = add nuw nsw i32 %14, %12, !dbg !34
  %16 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !35
  %17 = add nsw i32 %15, %16, !dbg !36
  ret i32 %17, !dbg !37
}

declare !dbg !38 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !43 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !46 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !49 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !52 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r04_measure_tree.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "22172bbd1fefc26de453ad94ca132a4b")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !13, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19, !20}
!17 = !DILocalVariable(name: "q", scope: !12, file: !8, line: 4, type: !15)
!18 = !DILocalVariable(name: "b0", scope: !12, file: !8, line: 5, type: !10)
!19 = !DILocalVariable(name: "b1", scope: !12, file: !8, line: 6, type: !10)
!20 = !DILocalVariable(name: "m", scope: !12, file: !8, line: 8, type: !15)
!21 = !DILocation(line: 4, column: 13, scope: !12)
!22 = !DILocation(line: 0, scope: !12)
!23 = !DILocation(line: 5, column: 15, scope: !12)
!24 = !DILocation(line: 7, column: 9, scope: !12)
!25 = !DILocation(line: 7, column: 20, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !8, line: 7, column: 13)
!27 = distinct !DILexicalBlock(scope: !12, file: !8, line: 7, column: 9)
!28 = !DILocation(line: 7, column: 39, scope: !26)
!29 = !DILocation(line: 8, column: 13, scope: !12)
!30 = !DILocation(line: 9, column: 12, scope: !31)
!31 = distinct !DILexicalBlock(scope: !12, file: !8, line: 9, column: 9)
!32 = !DILocation(line: 9, column: 22, scope: !31)
!33 = !DILocation(line: 10, column: 16, scope: !12)
!34 = !DILocation(line: 10, column: 14, scope: !12)
!35 = !DILocation(line: 10, column: 33, scope: !12)
!36 = !DILocation(line: 10, column: 31, scope: !12)
!37 = !DILocation(line: 10, column: 5, scope: !12)
!38 = !DISubprogram(name: "cq_theta_si32", scope: !39, file: !39, line: 38, type: !40, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!39 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!40 = !DISubroutineType(types: !41)
!41 = !{!15, !15, !42}
!42 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!43 = !DISubprogram(name: "cq_theta_i1", scope: !39, file: !39, line: 32, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DISubroutineType(types: !45)
!45 = !{!10, !10, !42}
!46 = !DISubprogram(name: "cq_measure_i1", scope: !39, file: !39, line: 77, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DISubroutineType(types: !48)
!48 = !{!10, !10}
!49 = !DISubprogram(name: "cq_phi", scope: !39, file: !39, line: 73, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!50 = !DISubroutineType(types: !51)
!51 = !{null, !42}
!52 = !DISubprogram(name: "cq_measure_si32", scope: !39, file: !39, line: 83, type: !53, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!53 = !DISubroutineType(types: !54)
!54 = !{!15, !15}
