; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p7_select_mix.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p7_select_mix.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2, !dbg !23
  %2 = icmp ne i32 %1, 0, !dbg !23
    #dbg_value(i1 %2, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !24)
    #dbg_value(i8 0, !18, !DIExpression(), !24)
    #dbg_value(i8 0, !19, !DIExpression(), !24)
    #dbg_value(i32 5, !20, !DIExpression(), !24)
    #dbg_value(i32 2, !21, !DIExpression(), !24)
  br i1 %2, label %3, label %5, !dbg !25

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !26
    #dbg_value(i1 %4, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !24)
  br label %5, !dbg !29

5:                                                ; preds = %0, %3
  %6 = phi i1 [ %4, %3 ], [ false, %0 ], !dbg !24
    #dbg_value(i8 poison, !18, !DIExpression(), !24)
    #dbg_value(i32 2, !22, !DIExpression(), !24)
    #dbg_value(i8 0, !19, !DIExpression(), !24)
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #2, !dbg !30
  %8 = zext i1 %7 to i32, !dbg !30
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !31
  %10 = zext i1 %9 to i32, !dbg !31
  %11 = add nuw nsw i32 %10, %8, !dbg !32
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext false) #2, !dbg !33
  %13 = zext i1 %12 to i32, !dbg !33
  %14 = add nuw nsw i32 %11, %13, !dbg !34
  %15 = tail call i32 @cq_measure_si32(i32 noundef 2) #2, !dbg !35
  %16 = add nsw i32 %14, %15, !dbg !36
  ret i32 %16, !dbg !37
}

declare !dbg !38 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !43 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !46 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !49 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p7_select_mix.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "825e28e8620e5bbb0bf388004bac6dc1")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 4, type: !12, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p7_select_mix.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "825e28e8620e5bbb0bf388004bac6dc1")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !18, !19, !20, !21, !22}
!16 = !DILocalVariable(name: "q", scope: !10, file: !11, line: 5, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 6, type: !17)
!19 = !DILocalVariable(name: "b2", scope: !10, file: !11, line: 6, type: !17)
!20 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 7, type: !14)
!21 = !DILocalVariable(name: "indep", scope: !10, file: !11, line: 7, type: !14)
!22 = !DILocalVariable(name: "mixed", scope: !10, file: !11, line: 9, type: !14)
!23 = !DILocation(line: 5, column: 14, scope: !10)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 8, column: 9, scope: !10)
!26 = !DILocation(line: 8, column: 19, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !11, line: 8, column: 12)
!28 = distinct !DILexicalBlock(scope: !10, file: !11, line: 8, column: 9)
!29 = !DILocation(line: 8, column: 38, scope: !27)
!30 = !DILocation(line: 11, column: 12, scope: !10)
!31 = !DILocation(line: 11, column: 26, scope: !10)
!32 = !DILocation(line: 11, column: 25, scope: !10)
!33 = !DILocation(line: 11, column: 41, scope: !10)
!34 = !DILocation(line: 11, column: 40, scope: !10)
!35 = !DILocation(line: 11, column: 56, scope: !10)
!36 = !DILocation(line: 11, column: 55, scope: !10)
!37 = !DILocation(line: 11, column: 5, scope: !10)
!38 = !DISubprogram(name: "cq_theta_si32", scope: !39, file: !39, line: 38, type: !40, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!39 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!40 = !DISubroutineType(types: !41)
!41 = !{!14, !14, !42}
!42 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!43 = !DISubprogram(name: "cq_theta_i1", scope: !39, file: !39, line: 32, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DISubroutineType(types: !45)
!45 = !{!17, !17, !42}
!46 = !DISubprogram(name: "cq_measure_i1", scope: !39, file: !39, line: 77, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DISubroutineType(types: !48)
!48 = !{!17, !17}
!49 = !DISubprogram(name: "cq_measure_si32", scope: !39, file: !39, line: 83, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!50 = !DISubroutineType(types: !51)
!51 = !{!14, !14}
