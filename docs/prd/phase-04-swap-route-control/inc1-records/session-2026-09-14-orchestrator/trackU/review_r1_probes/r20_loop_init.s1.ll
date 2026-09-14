; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r20_loop_init.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r20_loop_init.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !16, !DIExpression(), !22)
    #dbg_value(i8 0, !17, !DIExpression(), !22)
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !23
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i32 0, !19, !DIExpression(), !26)
    #dbg_value(i32 0, !19, !DIExpression(), !26)
    #dbg_value(i32 5, !16, !DIExpression(), !22)
    #dbg_value(i32 poison, !19, !DIExpression(), !26)
    #dbg_value(i32 poison, !16, !DIExpression(), !22)
    #dbg_value(i8 0, !21, !DIExpression(), !22)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 2.500000e-01) #2, !dbg !27
    #dbg_value(i1 %2, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
  %3 = select i1 %1, i32 2, i32 5, !dbg !30
    #dbg_value(i8 poison, !21, !DIExpression(), !22)
  %4 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !31
  %5 = zext i1 %4 to i32, !dbg !31
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #2, !dbg !32
  %7 = zext i1 %6 to i32, !dbg !32
  %8 = add nuw nsw i32 %7, %5, !dbg !33
  %9 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !34
  %10 = add nsw i32 %8, %9, !dbg !35
  ret i32 %10, !dbg !36
}

declare !dbg !37 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !42 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !45 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r20_loop_init.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "4a33e75139137eaccedb92be47ebb9ad")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 2, type: !12, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r20_loop_init.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "4a33e75139137eaccedb92be47ebb9ad")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !19, !21}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 3, type: !14)
!17 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 4, type: !18)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !DILocalVariable(name: "i", scope: !20, file: !11, line: 6, type: !14)
!20 = distinct !DILexicalBlock(scope: !10, file: !11, line: 6, column: 5)
!21 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 9, type: !18)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 5, column: 23, scope: !24)
!24 = distinct !DILexicalBlock(scope: !25, file: !11, line: 5, column: 16)
!25 = distinct !DILexicalBlock(scope: !10, file: !11, line: 5, column: 9)
!26 = !DILocation(line: 0, scope: !20)
!27 = !DILocation(line: 10, column: 23, scope: !28)
!28 = distinct !DILexicalBlock(scope: !29, file: !11, line: 10, column: 16)
!29 = distinct !DILexicalBlock(scope: !10, file: !11, line: 10, column: 9)
!30 = !DILocation(line: 6, column: 5, scope: !20)
!31 = !DILocation(line: 11, column: 12, scope: !10)
!32 = !DILocation(line: 11, column: 29, scope: !10)
!33 = !DILocation(line: 11, column: 27, scope: !10)
!34 = !DILocation(line: 11, column: 46, scope: !10)
!35 = !DILocation(line: 11, column: 44, scope: !10)
!36 = !DILocation(line: 11, column: 5, scope: !10)
!37 = !DISubprogram(name: "cq_theta_i1", scope: !38, file: !38, line: 32, type: !39, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!39 = !DISubroutineType(types: !40)
!40 = !{!18, !18, !41}
!41 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!42 = !DISubprogram(name: "cq_measure_i1", scope: !38, file: !38, line: 77, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DISubroutineType(types: !44)
!44 = !{!18, !18}
!45 = !DISubprogram(name: "cq_measure_si32", scope: !38, file: !38, line: 83, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DISubroutineType(types: !47)
!47 = !{!14, !14}
