; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r23_phi_prep_false_edge.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r23_phi_prep_false_edge.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @main() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !19
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
    #dbg_value(i8 0, !18, !DIExpression(), !20)
  br i1 %1, label %4, label %2, !dbg !21

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i1 %3, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
  br label %4, !dbg !25

4:                                                ; preds = %2, %0
  %5 = phi i1 [ false, %0 ], [ %3, %2 ], !dbg !20
    #dbg_value(i8 poison, !18, !DIExpression(), !20)
  br i1 %5, label %6, label %7, !dbg !26

6:                                                ; preds = %4
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !27
  br label %7, !dbg !27

7:                                                ; preds = %6, %4
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !29
  %9 = zext i1 %8 to i32, !dbg !29
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2, !dbg !30
  %11 = zext i1 %10 to i32, !dbg !30
  %12 = add nuw nsw i32 %11, %9, !dbg !31
  ret i32 %12, !dbg !32
}

declare !dbg !33 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !38 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !41 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r23_phi_prep_false_edge.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "0ec2d1f9f795e034811557c7661f01f0")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !13, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18}
!17 = !DILocalVariable(name: "b0", scope: !12, file: !8, line: 5, type: !10)
!18 = !DILocalVariable(name: "b1", scope: !12, file: !8, line: 6, type: !10)
!19 = !DILocation(line: 5, column: 15, scope: !12)
!20 = !DILocation(line: 0, scope: !12)
!21 = !DILocation(line: 7, column: 9, scope: !12)
!22 = !DILocation(line: 7, column: 21, scope: !23)
!23 = distinct !DILexicalBlock(scope: !24, file: !8, line: 7, column: 14)
!24 = distinct !DILexicalBlock(scope: !12, file: !8, line: 7, column: 9)
!25 = !DILocation(line: 7, column: 40, scope: !23)
!26 = !DILocation(line: 8, column: 9, scope: !12)
!27 = !DILocation(line: 8, column: 13, scope: !28)
!28 = distinct !DILexicalBlock(scope: !12, file: !8, line: 8, column: 9)
!29 = !DILocation(line: 9, column: 12, scope: !12)
!30 = !DILocation(line: 9, column: 29, scope: !12)
!31 = !DILocation(line: 9, column: 27, scope: !12)
!32 = !DILocation(line: 9, column: 5, scope: !12)
!33 = !DISubprogram(name: "cq_theta_i1", scope: !34, file: !34, line: 32, type: !35, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!34 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!35 = !DISubroutineType(types: !36)
!36 = !{!10, !10, !37}
!37 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!38 = !DISubprogram(name: "cq_phi", scope: !34, file: !34, line: 73, type: !39, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!39 = !DISubroutineType(types: !40)
!40 = !{null, !37}
!41 = !DISubprogram(name: "cq_measure_i1", scope: !34, file: !34, line: 77, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DISubroutineType(types: !43)
!43 = !{!10, !10}
