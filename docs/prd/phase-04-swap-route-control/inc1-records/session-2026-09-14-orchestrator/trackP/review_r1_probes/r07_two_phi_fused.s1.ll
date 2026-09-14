; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r07_two_phi_fused.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r07_two_phi_fused.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 4) i32 @main() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !20
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
    #dbg_value(i8 0, !18, !DIExpression(), !21)
    #dbg_value(i8 0, !19, !DIExpression(), !21)
  br i1 %1, label %2, label %5, !dbg !22

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !23
    #dbg_value(i1 %3, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 9.000000e-01) #2, !dbg !26
    #dbg_value(i1 %4, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
  br label %5, !dbg !27

5:                                                ; preds = %2, %0
  %6 = phi i1 [ %3, %2 ], [ false, %0 ], !dbg !21
  %7 = phi i1 [ %4, %2 ], [ false, %0 ], !dbg !21
    #dbg_value(i8 poison, !19, !DIExpression(), !21)
    #dbg_value(i8 poison, !18, !DIExpression(), !21)
  %8 = select i1 %6, i1 %7, i1 false, !dbg !28
  br i1 %8, label %9, label %10, !dbg !28

9:                                                ; preds = %5
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !30
  br label %10, !dbg !30

10:                                               ; preds = %5, %9
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !31
  %12 = zext i1 %11 to i32, !dbg !31
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !32
  %14 = zext i1 %13 to i32, !dbg !32
  %15 = add nuw nsw i32 %14, %12, !dbg !33
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #2, !dbg !34
  %17 = zext i1 %16 to i32, !dbg !34
  %18 = add nuw nsw i32 %15, %17, !dbg !35
  ret i32 %18, !dbg !36
}

declare !dbg !37 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !42 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !45 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r07_two_phi_fused.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "47f4fcb6dd1ffd206b5a2938d3a69417")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 6, type: !13, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19}
!17 = !DILocalVariable(name: "b0", scope: !12, file: !8, line: 7, type: !10)
!18 = !DILocalVariable(name: "b1", scope: !12, file: !8, line: 8, type: !10)
!19 = !DILocalVariable(name: "b2", scope: !12, file: !8, line: 9, type: !10)
!20 = !DILocation(line: 7, column: 15, scope: !12)
!21 = !DILocation(line: 0, scope: !12)
!22 = !DILocation(line: 10, column: 9, scope: !12)
!23 = !DILocation(line: 10, column: 20, scope: !24)
!24 = distinct !DILexicalBlock(scope: !25, file: !8, line: 10, column: 13)
!25 = distinct !DILexicalBlock(scope: !12, file: !8, line: 10, column: 9)
!26 = !DILocation(line: 10, column: 44, scope: !24)
!27 = !DILocation(line: 10, column: 63, scope: !24)
!28 = !DILocation(line: 11, column: 12, scope: !29)
!29 = distinct !DILexicalBlock(scope: !12, file: !8, line: 11, column: 9)
!30 = !DILocation(line: 11, column: 19, scope: !29)
!31 = !DILocation(line: 12, column: 12, scope: !12)
!32 = !DILocation(line: 12, column: 29, scope: !12)
!33 = !DILocation(line: 12, column: 27, scope: !12)
!34 = !DILocation(line: 12, column: 46, scope: !12)
!35 = !DILocation(line: 12, column: 44, scope: !12)
!36 = !DILocation(line: 12, column: 5, scope: !12)
!37 = !DISubprogram(name: "cq_theta_i1", scope: !38, file: !38, line: 32, type: !39, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!39 = !DISubroutineType(types: !40)
!40 = !{!10, !10, !41}
!41 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!42 = !DISubprogram(name: "cq_phi", scope: !38, file: !38, line: 73, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DISubroutineType(types: !44)
!44 = !{null, !41}
!45 = !DISubprogram(name: "cq_measure_i1", scope: !38, file: !38, line: 77, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DISubroutineType(types: !47)
!47 = !{!10, !10}
