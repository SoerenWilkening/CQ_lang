; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.DYIYf8EQEK/s1.ll'
source_filename = "./w2l_inplace_plus_chain_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !13 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !26
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !26
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !27)
  %h1 = call i32 @cqrt_alloc_i32(i32 5), !dbg !28
  call void @cqrt_ry_i32(i32 %h1, double 5.000000e-01), !dbg !28
    #dbg_value(i32 %h1, !19, !DIExpression(), !27)
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !29
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01), !dbg !29
    #dbg_value(i32 %h2, !20, !DIExpression(), !27)
    #dbg_value(i32 0, !21, !DIExpression(), !27)
  %h3 = call i32 @cqrt_alloc_i32(i32 6), !dbg !30
  call void @cqrt_ry_i32(i32 %h3, double 4.000000e-01), !dbg !30
    #dbg_value(i32 %h3, !22, !DIExpression(), !31)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 3.000000e-01), !dbg !32
    #dbg_value(i32 %h2, !20, !DIExpression(), !27)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %h1, i32 3), !dbg !34
    #dbg_value(i32 %h_op, !19, !DIExpression(), !27)
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !35
  %h_op5 = call i32 @cq_template_lshr_i32_hl(i32 %h3, i32 1), !dbg !36
  %h_op6 = call i32 @cq_template_and_i32_hl(i32 %h_op5, i32 1), !dbg !36
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op5, i32 %h3, i32 1), !dbg !36
  call void @cqrt_free(i32 %h_op5), !dbg !36
  %m10 = call i32 @cqrt_measure_i32(i32 %h_op6), !dbg !36
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h), !dbg !37
  %m11 = call i32 @cqrt_measure_i32(i32 %h_cast), !dbg !37
    #dbg_value(!DIArgList(i32 %m, i32 %m11, i32 %m10), !21, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 2, DW_OP_plus, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !27)
  %h4 = call i32 @cqrt_alloc_i32(i32 6), !dbg !38
  call void @cqrt_ry_i32(i32 %h4, double 4.000000e-01), !dbg !38
    #dbg_value(i32 %h4, !24, !DIExpression(), !39)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 3.000000e-01), !dbg !40
    #dbg_value(!DIArgList(i32 poison, i32 poison), !21, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !27)
    #dbg_value(i32 poison, !21, !DIExpression(), !27)
    #dbg_value(i32 %h2, !20, !DIExpression(), !27)
  %h_op7 = call i32 @cq_template_add_i32_hl(i32 %h1, i32 6), !dbg !42
    #dbg_value(i32 %h_op7, !19, !DIExpression(), !27)
  %m12 = call i32 @cqrt_measure_i32(i32 %h_op7), !dbg !43
  %h_op8 = call i32 @cq_template_lshr_i32_hl(i32 %h4, i32 1), !dbg !44
  %h_op9 = call i32 @cq_template_and_i32_hl(i32 %h_op8, i32 1), !dbg !44
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op8, i32 %h4, i32 1), !dbg !44
  call void @cqrt_free(i32 %h_op8), !dbg !44
  %m13 = call i32 @cqrt_measure_i32(i32 %h_op9), !dbg !44
  %m14 = call i32 @cqrt_measure_i32(i32 %h_cast), !dbg !45
    #dbg_value(i32 %5, !21, !DIExpression(), !27)
  %m15 = call i32 @cqrt_measure_i32(i32 %h2), !dbg !46
  %1 = add i32 %m10, %m, !dbg !47
  %2 = add i32 %1, %m11, !dbg !48
  %3 = add i32 %2, %m12, !dbg !49
  %4 = add i32 %3, %m13, !dbg !50
  %5 = add i32 %4, %m14, !dbg !51
  %6 = add nsw i32 %5, %m15, !dbg !52
  ret i32 %6, !dbg !53
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !54 {
  %1 = tail call i32 @slice(), !dbg !55
  ret i32 %1, !dbg !56
}

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!12}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "w2l_inplace_plus_chain_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "1b1e5c7ead0e452d7e3d653882fe1942")
!9 = !{!10, !11}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!12 = !{!"Homebrew clang version 19.1.7"}
!13 = distinct !DISubprogram(name: "slice", scope: !14, file: !14, line: 3, type: !15, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!14 = !DIFile(filename: "./w2l_inplace_plus_chain_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "1b1e5c7ead0e452d7e3d653882fe1942")
!15 = !DISubroutineType(types: !16)
!16 = !{!11}
!17 = !{!18, !19, !20, !21, !22, !24}
!18 = !DILocalVariable(name: "b", scope: !13, file: !14, line: 4, type: !10)
!19 = !DILocalVariable(name: "q", scope: !13, file: !14, line: 5, type: !11)
!20 = !DILocalVariable(name: "r", scope: !13, file: !14, line: 6, type: !11)
!21 = !DILocalVariable(name: "s", scope: !13, file: !14, line: 7, type: !11)
!22 = !DILocalVariable(name: "u", scope: !23, file: !14, line: 8, type: !11)
!23 = distinct !DILexicalBlock(scope: !13, file: !14, line: 8, column: 5)
!24 = !DILocalVariable(name: "u", scope: !25, file: !14, line: 10, type: !11)
!25 = distinct !DILexicalBlock(scope: !13, file: !14, line: 10, column: 5)
!26 = !DILocation(line: 4, column: 14, scope: !13)
!27 = !DILocation(line: 0, scope: !13)
!28 = !DILocation(line: 5, column: 14, scope: !13)
!29 = !DILocation(line: 6, column: 14, scope: !13)
!30 = !DILocation(line: 8, column: 15, scope: !23)
!31 = !DILocation(line: 0, scope: !23)
!32 = !DILocation(line: 8, column: 44, scope: !33)
!33 = distinct !DILexicalBlock(scope: !23, file: !14, line: 8, column: 37)
!34 = !DILocation(line: 8, column: 68, scope: !23)
!35 = !DILocation(line: 9, column: 12, scope: !23)
!36 = !DILocation(line: 9, column: 28, scope: !23)
!37 = !DILocation(line: 9, column: 55, scope: !23)
!38 = !DILocation(line: 10, column: 15, scope: !25)
!39 = !DILocation(line: 0, scope: !25)
!40 = !DILocation(line: 10, column: 44, scope: !41)
!41 = distinct !DILexicalBlock(scope: !25, file: !14, line: 10, column: 37)
!42 = !DILocation(line: 10, column: 68, scope: !25)
!43 = !DILocation(line: 11, column: 12, scope: !25)
!44 = !DILocation(line: 11, column: 28, scope: !25)
!45 = !DILocation(line: 11, column: 55, scope: !25)
!46 = !DILocation(line: 12, column: 16, scope: !13)
!47 = !DILocation(line: 11, column: 26, scope: !25)
!48 = !DILocation(line: 11, column: 53, scope: !25)
!49 = !DILocation(line: 9, column: 26, scope: !23)
!50 = !DILocation(line: 9, column: 53, scope: !23)
!51 = !DILocation(line: 11, column: 9, scope: !25)
!52 = !DILocation(line: 12, column: 14, scope: !13)
!53 = !DILocation(line: 12, column: 5, scope: !13)
!54 = distinct !DISubprogram(name: "main", scope: !14, file: !14, line: 14, type: !15, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!55 = !DILocation(line: 14, column: 25, scope: !54)
!56 = !DILocation(line: 14, column: 18, scope: !54)
