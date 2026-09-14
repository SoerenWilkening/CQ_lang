; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.nMe7fIHyJb/s1.ll'
source_filename = "./w2h3_select_iterlocal_invread_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !28
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !28
    #dbg_value(i32 %h, !18, !DIExpression(), !29)
    #dbg_value(i32 0, !19, !DIExpression(), !29)
  %h6 = call i32 @cqrt_alloc_i32(i32 6), !dbg !30
  call void @cqrt_ry_i32(i32 %h6, double 4.000000e-01), !dbg !30
    #dbg_value(i32 %h6, !20, !DIExpression(), !31)
  %h7 = call i32 @cqrt_alloc_i1(i1 false), !dbg !32
  call void @cqrt_ry_i1(i32 %h7, double 5.000000e-01), !dbg !32
    #dbg_value(i32 %h7, !22, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !31)
  %bf = call i32 @cqrt_alloc_i1(i1 false), !dbg !33
  call void @cqrt_cnot(i32 %h7, i32 %bf), !dbg !33
  %out = call i32 @cqrt_alloc_i32(i32 0), !dbg !33
  %selop = call i32 @cqrt_alloc_i32(i32 2), !dbg !33
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out), !dbg !33
  call void @cqrt_x(i32 %bf), !dbg !33
  %selop1 = call i32 @cqrt_alloc_i32(i32 5), !dbg !33
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out), !dbg !33
  call void @cqrt_x(i32 %bf), !dbg !33
  call void @cqrt_cnot(i32 %h7, i32 %bf), !dbg !33
  call void @cqrt_free(i32 %bf), !dbg !33
    #dbg_value(i32 %out, !23, !DIExpression(), !31)
  %m = call i32 @cqrt_measure_i32(i32 %out), !dbg !34
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h6, i32 1), !dbg !35
  %h_op10 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !35
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h6, i32 1), !dbg !35
  call void @cqrt_free(i32 %h_op), !dbg !35
  %m14 = call i32 @cqrt_measure_i32(i32 %h_op10), !dbg !35
  %h_op11 = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !36
  %m15 = call i32 @cqrt_measure_i32(i32 %h_op11), !dbg !36
    #dbg_value(i32 poison, !19, !DIExpression(), !29)
  %h8 = call i32 @cqrt_alloc_i32(i32 6), !dbg !37
  call void @cqrt_ry_i32(i32 %h8, double 4.000000e-01), !dbg !37
    #dbg_value(i32 %h8, !24, !DIExpression(), !38)
  %h9 = call i32 @cqrt_alloc_i1(i1 false), !dbg !39
  call void @cqrt_ry_i1(i32 %h9, double 5.000000e-01), !dbg !39
    #dbg_value(i32 %h9, !26, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !38)
  %bf2 = call i32 @cqrt_alloc_i1(i1 false), !dbg !40
  call void @cqrt_cnot(i32 %h9, i32 %bf2), !dbg !40
  %out3 = call i32 @cqrt_alloc_i32(i32 0), !dbg !40
  %selop4 = call i32 @cqrt_alloc_i32(i32 2), !dbg !40
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %selop4, i32 %out3), !dbg !40
  call void @cqrt_x(i32 %bf2), !dbg !40
  %selop5 = call i32 @cqrt_alloc_i32(i32 5), !dbg !40
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %selop5, i32 %out3), !dbg !40
  call void @cqrt_x(i32 %bf2), !dbg !40
  call void @cqrt_cnot(i32 %h9, i32 %bf2), !dbg !40
  call void @cqrt_free(i32 %bf2), !dbg !40
    #dbg_value(i32 %out3, !27, !DIExpression(), !38)
  %m16 = call i32 @cqrt_measure_i32(i32 %out3), !dbg !41
  %h_op12 = call i32 @cq_template_lshr_i32_hl(i32 %h8, i32 1), !dbg !42
  %h_op13 = call i32 @cq_template_and_i32_hl(i32 %h_op12, i32 1), !dbg !42
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op12, i32 %h8, i32 1), !dbg !42
  call void @cqrt_free(i32 %h_op12), !dbg !42
  %m17 = call i32 @cqrt_measure_i32(i32 %h_op13), !dbg !42
  %m18 = call i32 @cqrt_measure_i32(i32 %h_op11), !dbg !43
    #dbg_value(i32 %5, !19, !DIExpression(), !29)
  %m19 = call i32 @cqrt_measure_i32(i32 %h), !dbg !44
  %1 = add i32 %m14, %m, !dbg !45
  %2 = add i32 %1, %m15, !dbg !46
  %3 = add i32 %2, %m16, !dbg !47
  %4 = add i32 %3, %m17, !dbg !48
  %5 = add i32 %4, %m18, !dbg !49
  %6 = add nsw i32 %5, %m19, !dbg !50
  ret i32 %6, !dbg !51
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !52 {
  %1 = tail call i32 @slice(), !dbg !53
  ret i32 %1, !dbg !54
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

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
!8 = !DIFile(filename: "w2h3_select_iterlocal_invread_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "0e1b7baae057a4478e6b7719d156f459")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2h3_select_iterlocal_invread_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "0e1b7baae057a4478e6b7719d156f459")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !22, !23, !24, !26, !27}
!18 = !DILocalVariable(name: "y", scope: !12, file: !13, line: 4, type: !16)
!19 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 5, type: !16)
!20 = !DILocalVariable(name: "u", scope: !21, file: !13, line: 6, type: !16)
!21 = distinct !DILexicalBlock(scope: !12, file: !13, line: 6, column: 5)
!22 = !DILocalVariable(name: "b", scope: !21, file: !13, line: 6, type: !10)
!23 = !DILocalVariable(name: "a", scope: !21, file: !13, line: 6, type: !16)
!24 = !DILocalVariable(name: "u", scope: !25, file: !13, line: 8, type: !16)
!25 = distinct !DILexicalBlock(scope: !12, file: !13, line: 8, column: 5)
!26 = !DILocalVariable(name: "b", scope: !25, file: !13, line: 8, type: !10)
!27 = !DILocalVariable(name: "a", scope: !25, file: !13, line: 8, type: !16)
!28 = !DILocation(line: 4, column: 13, scope: !12)
!29 = !DILocation(line: 0, scope: !12)
!30 = !DILocation(line: 6, column: 15, scope: !21)
!31 = !DILocation(line: 0, scope: !21)
!32 = !DILocation(line: 6, column: 42, scope: !21)
!33 = !DILocation(line: 6, column: 74, scope: !21)
!34 = !DILocation(line: 7, column: 12, scope: !21)
!35 = !DILocation(line: 7, column: 28, scope: !21)
!36 = !DILocation(line: 7, column: 55, scope: !21)
!37 = !DILocation(line: 8, column: 15, scope: !25)
!38 = !DILocation(line: 0, scope: !25)
!39 = !DILocation(line: 8, column: 42, scope: !25)
!40 = !DILocation(line: 8, column: 74, scope: !25)
!41 = !DILocation(line: 9, column: 12, scope: !25)
!42 = !DILocation(line: 9, column: 28, scope: !25)
!43 = !DILocation(line: 9, column: 55, scope: !25)
!44 = !DILocation(line: 10, column: 16, scope: !12)
!45 = !DILocation(line: 9, column: 26, scope: !25)
!46 = !DILocation(line: 9, column: 53, scope: !25)
!47 = !DILocation(line: 7, column: 26, scope: !21)
!48 = !DILocation(line: 7, column: 53, scope: !21)
!49 = !DILocation(line: 9, column: 9, scope: !25)
!50 = !DILocation(line: 10, column: 14, scope: !12)
!51 = !DILocation(line: 10, column: 5, scope: !12)
!52 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 12, type: !14, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!53 = !DILocation(line: 12, column: 25, scope: !52)
!54 = !DILocation(line: 12, column: 18, scope: !52)
