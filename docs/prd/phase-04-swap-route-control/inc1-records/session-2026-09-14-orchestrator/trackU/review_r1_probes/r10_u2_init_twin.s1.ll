; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r10_u2_init_twin.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r10_u2_init_twin.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !16, !DIExpression(), !20)
    #dbg_value(i8 0, !17, !DIExpression(), !20)
    #dbg_value(i8 0, !19, !DIExpression(), !20)
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !21
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
    #dbg_value(i32 poison, !16, !DIExpression(), !20)
  br i1 %1, label %4, label %2, !dbg !24

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !25
    #dbg_value(i1 %3, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
  br label %4, !dbg !28

4:                                                ; preds = %2, %0
  %5 = phi i32 [ 5, %2 ], [ 2, %0 ], !dbg !20
  %6 = phi i1 [ %3, %2 ], [ false, %0 ], !dbg !20
    #dbg_value(i32 %5, !16, !DIExpression(), !20)
    #dbg_value(i8 poison, !19, !DIExpression(), !20)
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !29
  %8 = zext i1 %7 to i32, !dbg !29
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !30
  %10 = zext i1 %9 to i32, !dbg !30
  %11 = add nuw nsw i32 %10, %8, !dbg !31
  %12 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !32
  %13 = add nsw i32 %11, %12, !dbg !33
  ret i32 %13, !dbg !34
}

declare !dbg !35 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !40 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !43 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r10_u2_init_twin.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "8b16ef026485cb458fa050dcb5409c5e")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 3, type: !12, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r10_u2_init_twin.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "8b16ef026485cb458fa050dcb5409c5e")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !19}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 4, type: !14)
!17 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 5, type: !18)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 6, type: !18)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 7, column: 23, scope: !22)
!22 = distinct !DILexicalBlock(scope: !23, file: !11, line: 7, column: 16)
!23 = distinct !DILexicalBlock(scope: !10, file: !11, line: 7, column: 9)
!24 = !DILocation(line: 9, column: 9, scope: !10)
!25 = !DILocation(line: 9, column: 23, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !11, line: 9, column: 16)
!27 = distinct !DILexicalBlock(scope: !10, file: !11, line: 9, column: 9)
!28 = !DILocation(line: 9, column: 42, scope: !26)
!29 = !DILocation(line: 10, column: 12, scope: !10)
!30 = !DILocation(line: 10, column: 29, scope: !10)
!31 = !DILocation(line: 10, column: 27, scope: !10)
!32 = !DILocation(line: 10, column: 46, scope: !10)
!33 = !DILocation(line: 10, column: 44, scope: !10)
!34 = !DILocation(line: 10, column: 5, scope: !10)
!35 = !DISubprogram(name: "cq_theta_i1", scope: !36, file: !36, line: 32, type: !37, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!36 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!37 = !DISubroutineType(types: !38)
!38 = !{!18, !18, !39}
!39 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!40 = !DISubprogram(name: "cq_measure_i1", scope: !36, file: !36, line: 77, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DISubroutineType(types: !42)
!42 = !{!18, !18}
!43 = !DISubprogram(name: "cq_measure_si32", scope: !36, file: !36, line: 83, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DISubroutineType(types: !45)
!45 = !{!14, !14}
