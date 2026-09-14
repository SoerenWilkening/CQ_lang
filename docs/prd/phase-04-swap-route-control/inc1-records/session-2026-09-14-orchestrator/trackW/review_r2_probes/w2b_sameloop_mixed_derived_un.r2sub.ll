; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.ABVgM8aghp/s1.ll'
source_filename = "./w2b_sameloop_mixed_derived_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !27
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !27
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !28)
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !29
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01), !dbg !29
    #dbg_value(i32 %h2, !19, !DIExpression(), !28)
    #dbg_value(i32 0, !20, !DIExpression(), !28)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 3.000000e-01), !dbg !30
    #dbg_value(i32 %h2, !19, !DIExpression(), !28)
  %h3 = call i32 @cqrt_alloc_i32(i32 5), !dbg !32
  call void @cqrt_ry_i32(i32 %h3, double 5.000000e-01), !dbg !32
    #dbg_value(i32 %h3, !21, !DIExpression(), !33)
  %h4 = call i32 @cqrt_alloc_i32(i32 3), !dbg !34
  call void @cqrt_ry_i32(i32 %h4, double 1.500000e-01), !dbg !34
    #dbg_value(i32 %h4, !23, !DIExpression(), !33)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h3, i32 2), !dbg !35
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !35
  call void @cqrt_x(i32 %h_cmp1), !dbg !37
  call void @cqrt_ry_i32_controlled(i32 %h_cmp1, i32 %h4, double 2.000000e-01), !dbg !38
  call void @cqrt_x(i32 %h_cmp1), !dbg !37
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op, i32 0), !dbg !35
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h3, i32 2), !dbg !35
  call void @cqrt_free(i32 %h_op), !dbg !35
  call void @cqrt_free(i32 %h_cmp1), !dbg !37
    #dbg_value(i32 %h4, !23, !DIExpression(), !33)
  %m = call i32 @cqrt_measure_i32(i32 %h2), !dbg !39
  %m8 = call i32 @cqrt_measure_i32(i32 %h4), !dbg !40
  %m9 = call i32 @cqrt_measure_i32(i32 %h3), !dbg !41
    #dbg_value(!DIArgList(i32 %m, i32 %m9, i32 %m8), !20, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 2, DW_OP_plus, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !28)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 3.000000e-01), !dbg !42
    #dbg_value(i32 %h2, !19, !DIExpression(), !28)
  %h5 = call i32 @cqrt_alloc_i32(i32 5), !dbg !44
  call void @cqrt_ry_i32(i32 %h5, double 5.000000e-01), !dbg !44
    #dbg_value(i32 %h5, !24, !DIExpression(), !45)
  %h6 = call i32 @cqrt_alloc_i32(i32 3), !dbg !46
  call void @cqrt_ry_i32(i32 %h6, double 1.500000e-01), !dbg !46
    #dbg_value(i32 %h6, !26, !DIExpression(), !45)
  %h_op7 = call i32 @cq_template_and_i32_hl(i32 %h5, i32 2), !dbg !47
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op7, i32 0), !dbg !47
  call void @cqrt_x(i32 %h_cmp), !dbg !49
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h6, double 2.000000e-01), !dbg !50
  call void @cqrt_x(i32 %h_cmp), !dbg !49
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op7, i32 0), !dbg !47
  call void @cq_template_and_i32_hl_unc(i32 %h_op7, i32 %h5, i32 2), !dbg !47
  call void @cqrt_free(i32 %h_op7), !dbg !47
  call void @cqrt_free(i32 %h_cmp), !dbg !49
    #dbg_value(!DIArgList(i32 poison, i32 poison), !20, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !28)
    #dbg_value(i32 poison, !20, !DIExpression(), !28)
    #dbg_value(i32 %h6, !26, !DIExpression(), !45)
  %m10 = call i32 @cqrt_measure_i32(i32 %h2), !dbg !51
  %m11 = call i32 @cqrt_measure_i32(i32 %h6), !dbg !52
  %m12 = call i32 @cqrt_measure_i32(i32 %h5), !dbg !53
  %1 = add i32 %m8, %m, !dbg !54
  %2 = add i32 %1, %m9, !dbg !55
  %3 = add i32 %2, %m10, !dbg !56
  %4 = add i32 %3, %m11, !dbg !57
  %5 = add i32 %4, %m12, !dbg !58
    #dbg_value(i32 %5, !20, !DIExpression(), !28)
  ret i32 %5, !dbg !59
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !60 {
  %1 = tail call i32 @slice(), !dbg !61
  ret i32 %1, !dbg !62
}

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

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
!8 = !DIFile(filename: "w2b_sameloop_mixed_derived_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "5079954a78558457e848351de711edfd")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2b_sameloop_mixed_derived_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "5079954a78558457e848351de711edfd")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21, !23, !24, !26}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 4, type: !10)
!19 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 5, type: !16)
!20 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 6, type: !16)
!21 = !DILocalVariable(name: "u", scope: !22, file: !13, line: 8, type: !16)
!22 = distinct !DILexicalBlock(scope: !12, file: !13, line: 7, column: 5)
!23 = !DILocalVariable(name: "w", scope: !22, file: !13, line: 8, type: !16)
!24 = !DILocalVariable(name: "u", scope: !25, file: !13, line: 12, type: !16)
!25 = distinct !DILexicalBlock(scope: !12, file: !13, line: 11, column: 5)
!26 = !DILocalVariable(name: "w", scope: !25, file: !13, line: 12, type: !16)
!27 = !DILocation(line: 4, column: 14, scope: !12)
!28 = !DILocation(line: 0, scope: !12)
!29 = !DILocation(line: 5, column: 14, scope: !12)
!30 = !DILocation(line: 7, column: 18, scope: !31)
!31 = distinct !DILexicalBlock(scope: !22, file: !13, line: 7, column: 11)
!32 = !DILocation(line: 8, column: 15, scope: !22)
!33 = !DILocation(line: 0, scope: !22)
!34 = !DILocation(line: 8, column: 41, scope: !22)
!35 = !DILocation(line: 9, column: 20, scope: !36)
!36 = distinct !DILexicalBlock(scope: !22, file: !13, line: 9, column: 11)
!37 = !DILocation(line: 9, column: 11, scope: !22)
!38 = !DILocation(line: 9, column: 29, scope: !36)
!39 = !DILocation(line: 10, column: 12, scope: !22)
!40 = !DILocation(line: 10, column: 28, scope: !22)
!41 = !DILocation(line: 10, column: 44, scope: !22)
!42 = !DILocation(line: 11, column: 18, scope: !43)
!43 = distinct !DILexicalBlock(scope: !25, file: !13, line: 11, column: 11)
!44 = !DILocation(line: 12, column: 15, scope: !25)
!45 = !DILocation(line: 0, scope: !25)
!46 = !DILocation(line: 12, column: 41, scope: !25)
!47 = !DILocation(line: 13, column: 20, scope: !48)
!48 = distinct !DILexicalBlock(scope: !25, file: !13, line: 13, column: 11)
!49 = !DILocation(line: 13, column: 11, scope: !25)
!50 = !DILocation(line: 13, column: 29, scope: !48)
!51 = !DILocation(line: 14, column: 12, scope: !25)
!52 = !DILocation(line: 14, column: 28, scope: !25)
!53 = !DILocation(line: 14, column: 44, scope: !25)
!54 = !DILocation(line: 14, column: 26, scope: !25)
!55 = !DILocation(line: 14, column: 42, scope: !25)
!56 = !DILocation(line: 10, column: 26, scope: !22)
!57 = !DILocation(line: 10, column: 42, scope: !22)
!58 = !DILocation(line: 14, column: 9, scope: !25)
!59 = !DILocation(line: 15, column: 5, scope: !12)
!60 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 17, type: !14, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!61 = !DILocation(line: 17, column: 25, scope: !60)
!62 = !DILocation(line: 17, column: 18, scope: !60)
