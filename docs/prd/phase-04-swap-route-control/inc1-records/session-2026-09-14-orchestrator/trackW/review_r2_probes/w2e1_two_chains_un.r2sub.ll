; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.JoKseVO9qg/s1.ll'
source_filename = "./w2e1_two_chains_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !27
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !27
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !28)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !29
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !29
    #dbg_value(i32 %h1, !19, !DIExpression(), !28)
    #dbg_value(i32 0, !20, !DIExpression(), !28)
  %h2 = call i32 @cqrt_alloc_i32(i32 5), !dbg !30
  call void @cqrt_ry_i32(i32 %h2, double 5.000000e-01), !dbg !30
    #dbg_value(i32 %h2, !21, !DIExpression(), !31)
  %h3 = call i32 @cqrt_alloc_i32(i32 6), !dbg !32
  call void @cqrt_ry_i32(i32 %h3, double 4.000000e-01), !dbg !32
    #dbg_value(i32 %h3, !23, !DIExpression(), !31)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 3.000000e-01), !dbg !33
    #dbg_value(i32 %h1, !19, !DIExpression(), !28)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h2, i32 1), !dbg !35
  %h_op6 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !35
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h2, i32 1), !dbg !35
  call void @cqrt_free(i32 %h_op), !dbg !35
  %m = call i32 @cqrt_measure_i32(i32 %h_op6), !dbg !35
  %h_op7 = call i32 @cq_template_lshr_i32_hl(i32 %h3, i32 2), !dbg !36
  %h_op8 = call i32 @cq_template_and_i32_hl(i32 %h_op7, i32 3), !dbg !36
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op7, i32 %h3, i32 2), !dbg !36
  call void @cqrt_free(i32 %h_op7), !dbg !36
  %m13 = call i32 @cqrt_measure_i32(i32 %h_op8), !dbg !36
    #dbg_value(!DIArgList(i32 %m, i32 %m13), !20, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !28)
  %h4 = call i32 @cqrt_alloc_i32(i32 5), !dbg !37
  call void @cqrt_ry_i32(i32 %h4, double 5.000000e-01), !dbg !37
    #dbg_value(i32 %h4, !24, !DIExpression(), !38)
  %h5 = call i32 @cqrt_alloc_i32(i32 6), !dbg !39
  call void @cqrt_ry_i32(i32 %h5, double 4.000000e-01), !dbg !39
    #dbg_value(i32 %h5, !26, !DIExpression(), !38)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 3.000000e-01), !dbg !40
    #dbg_value(i32 poison, !20, !DIExpression(), !28)
    #dbg_value(i32 %h1, !19, !DIExpression(), !28)
  %h_op9 = call i32 @cq_template_lshr_i32_hl(i32 %h4, i32 1), !dbg !42
  %h_op10 = call i32 @cq_template_and_i32_hl(i32 %h_op9, i32 1), !dbg !42
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op9, i32 %h4, i32 1), !dbg !42
  call void @cqrt_free(i32 %h_op9), !dbg !42
  %m14 = call i32 @cqrt_measure_i32(i32 %h_op10), !dbg !42
  %h_op11 = call i32 @cq_template_lshr_i32_hl(i32 %h5, i32 2), !dbg !43
  %h_op12 = call i32 @cq_template_and_i32_hl(i32 %h_op11, i32 3), !dbg !43
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op11, i32 %h5, i32 2), !dbg !43
  call void @cqrt_free(i32 %h_op11), !dbg !43
  %m15 = call i32 @cqrt_measure_i32(i32 %h_op12), !dbg !43
    #dbg_value(i32 %4, !20, !DIExpression(), !28)
  %m16 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !44
  %m17 = call i1 @cqrt_measure_i1(i32 %h), !dbg !45
  %1 = zext i1 %m17 to i32, !dbg !45
  %2 = add i32 %m13, %m, !dbg !46
  %3 = add i32 %2, %m14, !dbg !47
  %4 = add i32 %3, %m15, !dbg !48
  %5 = add nsw i32 %4, %m16, !dbg !49
  %6 = add nsw i32 %5, %1, !dbg !50
  ret i32 %6, !dbg !51
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !52 {
  %1 = tail call i32 @slice(), !dbg !53
  ret i32 %1, !dbg !54
}

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare i1 @cqrt_measure_i1(i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

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
!8 = !DIFile(filename: "w2e1_two_chains_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "3f91e2fb4e0bb1a0dbbd2577c044bfd1")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2e1_two_chains_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "3f91e2fb4e0bb1a0dbbd2577c044bfd1")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21, !23, !24, !26}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 4, type: !10)
!19 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 5, type: !16)
!20 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 6, type: !16)
!21 = !DILocalVariable(name: "u", scope: !22, file: !13, line: 8, type: !16)
!22 = distinct !DILexicalBlock(scope: !12, file: !13, line: 7, column: 5)
!23 = !DILocalVariable(name: "v", scope: !22, file: !13, line: 9, type: !16)
!24 = !DILocalVariable(name: "u", scope: !25, file: !13, line: 14, type: !16)
!25 = distinct !DILexicalBlock(scope: !12, file: !13, line: 13, column: 5)
!26 = !DILocalVariable(name: "v", scope: !25, file: !13, line: 15, type: !16)
!27 = !DILocation(line: 4, column: 14, scope: !12)
!28 = !DILocation(line: 0, scope: !12)
!29 = !DILocation(line: 5, column: 14, scope: !12)
!30 = !DILocation(line: 8, column: 17, scope: !22)
!31 = !DILocation(line: 0, scope: !22)
!32 = !DILocation(line: 9, column: 17, scope: !22)
!33 = !DILocation(line: 10, column: 20, scope: !34)
!34 = distinct !DILexicalBlock(scope: !22, file: !13, line: 10, column: 13)
!35 = !DILocation(line: 11, column: 14, scope: !22)
!36 = !DILocation(line: 11, column: 41, scope: !22)
!37 = !DILocation(line: 14, column: 17, scope: !25)
!38 = !DILocation(line: 0, scope: !25)
!39 = !DILocation(line: 15, column: 17, scope: !25)
!40 = !DILocation(line: 16, column: 20, scope: !41)
!41 = distinct !DILexicalBlock(scope: !25, file: !13, line: 16, column: 13)
!42 = !DILocation(line: 17, column: 14, scope: !25)
!43 = !DILocation(line: 17, column: 41, scope: !25)
!44 = !DILocation(line: 19, column: 16, scope: !12)
!45 = !DILocation(line: 19, column: 32, scope: !12)
!46 = !DILocation(line: 17, column: 39, scope: !25)
!47 = !DILocation(line: 11, column: 39, scope: !22)
!48 = !DILocation(line: 17, column: 11, scope: !25)
!49 = !DILocation(line: 19, column: 14, scope: !12)
!50 = !DILocation(line: 19, column: 30, scope: !12)
!51 = !DILocation(line: 19, column: 5, scope: !12)
!52 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 21, type: !14, scopeLine: 21, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!53 = !DILocation(line: 21, column: 25, scope: !52)
!54 = !DILocation(line: 21, column: 18, scope: !52)
