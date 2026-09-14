; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r15_loop_header_phi.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r15_loop_header_phi.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !20
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
    #dbg_value(i32 0, !18, !DIExpression(), !22)
  br label %6, !dbg !23

2:                                                ; preds = %10
  %3 = xor i1 %1, true, !dbg !23
  %4 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #2, !dbg !24
  %5 = zext i1 %4 to i32, !dbg !24
  ret i32 %5, !dbg !25

6:                                                ; preds = %0, %10
  %7 = phi i32 [ 0, %0 ], [ %12, %10 ]
  %8 = phi i1 [ %1, %0 ], [ %11, %10 ]
    #dbg_value(i32 %7, !18, !DIExpression(), !22)
    #dbg_value(i1 %8, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
    #dbg_value(i1 %8, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
  br i1 %8, label %9, label %10, !dbg !26

9:                                                ; preds = %6
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !29
  br label %10, !dbg !29

10:                                               ; preds = %9, %6
  %11 = xor i1 %8, true, !dbg !31
    #dbg_value(i1 %11, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
  %12 = add nuw nsw i32 %7, 1, !dbg !32
    #dbg_value(i32 %12, !18, !DIExpression(), !22)
  %13 = icmp eq i32 %12, 3, !dbg !33
  br i1 %13, label %2, label %6, !dbg !23, !llvm.loop !34
}

declare !dbg !38 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !43 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !46 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r15_loop_header_phi.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "00851af95ab4e068ba523b6fc475da8c")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !13, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18}
!17 = !DILocalVariable(name: "b", scope: !12, file: !8, line: 6, type: !10)
!18 = !DILocalVariable(name: "i", scope: !19, file: !8, line: 7, type: !15)
!19 = distinct !DILexicalBlock(scope: !12, file: !8, line: 7, column: 5)
!20 = !DILocation(line: 6, column: 14, scope: !12)
!21 = !DILocation(line: 0, scope: !12)
!22 = !DILocation(line: 0, scope: !19)
!23 = !DILocation(line: 7, column: 5, scope: !19)
!24 = !DILocation(line: 11, column: 12, scope: !12)
!25 = !DILocation(line: 11, column: 5, scope: !12)
!26 = !DILocation(line: 8, column: 13, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !8, line: 7, column: 33)
!28 = distinct !DILexicalBlock(scope: !19, file: !8, line: 7, column: 5)
!29 = !DILocation(line: 8, column: 16, scope: !30)
!30 = distinct !DILexicalBlock(scope: !27, file: !8, line: 8, column: 13)
!31 = !DILocation(line: 9, column: 13, scope: !27)
!32 = !DILocation(line: 7, column: 28, scope: !28)
!33 = !DILocation(line: 7, column: 23, scope: !28)
!34 = distinct !{!34, !23, !35, !36, !37}
!35 = !DILocation(line: 10, column: 5, scope: !19)
!36 = !{!"llvm.loop.mustprogress"}
!37 = !{!"llvm.loop.unroll.disable"}
!38 = !DISubprogram(name: "cq_theta_i1", scope: !39, file: !39, line: 32, type: !40, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!39 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!40 = !DISubroutineType(types: !41)
!41 = !{!10, !10, !42}
!42 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!43 = !DISubprogram(name: "cq_phi", scope: !39, file: !39, line: 73, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DISubroutineType(types: !45)
!45 = !{null, !42}
!46 = !DISubprogram(name: "cq_measure_i1", scope: !39, file: !39, line: 77, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DISubroutineType(types: !48)
!48 = !{!10, !10}
