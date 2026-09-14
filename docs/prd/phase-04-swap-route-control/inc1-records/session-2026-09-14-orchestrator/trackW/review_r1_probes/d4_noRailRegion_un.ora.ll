; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.8IeFbMl0Al/s1.ll'
source_filename = "./d4_noRailRegion_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !13 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !25
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !25
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !26)
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !27
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01), !dbg !27
    #dbg_value(i32 %h2, !19, !DIExpression(), !26)
    #dbg_value(i32 0, !20, !DIExpression(), !26)
  %h3 = call i32 @cqrt_alloc_i32(i32 5), !dbg !28
  call void @cqrt_ry_i32(i32 %h3, double 5.000000e-01), !dbg !28
    #dbg_value(i32 %h3, !21, !DIExpression(), !29)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h3, i32 2), !dbg !30
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !30
  call void @cqrt_x(i32 %h_cmp1), !dbg !32
  call void @cqrt_ry_i32_controlled(i32 %h_cmp1, i32 %h2, double 2.000000e-01), !dbg !33
  call void @cqrt_x(i32 %h_cmp1), !dbg !32
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op, i32 0), !dbg !30
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h3, i32 2), !dbg !30
  call void @cqrt_free(i32 %h_op), !dbg !30
  call void @cqrt_free(i32 %h_cmp1), !dbg !32
    #dbg_value(i32 %h2, !19, !DIExpression(), !26)
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h), !dbg !34
  %h_op5 = call i32 @cq_template_add_i32(i32 %h3, i32 %h_cast), !dbg !34
  %m = call i32 @cqrt_measure_i32(i32 %h_op5), !dbg !34
    #dbg_value(i32 %m, !20, !DIExpression(), !26)
  %h4 = call i32 @cqrt_alloc_i32(i32 5), !dbg !35
  call void @cqrt_ry_i32(i32 %h4, double 5.000000e-01), !dbg !35
    #dbg_value(i32 %h4, !23, !DIExpression(), !36)
  %h_op6 = call i32 @cq_template_and_i32_hl(i32 %h4, i32 2), !dbg !37
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op6, i32 0), !dbg !37
  call void @cqrt_x(i32 %h_cmp), !dbg !39
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h2, double 2.000000e-01), !dbg !40
  call void @cqrt_x(i32 %h_cmp), !dbg !39
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op6, i32 0), !dbg !37
  call void @cq_template_and_i32_hl_unc(i32 %h_op6, i32 %h4, i32 2), !dbg !37
  call void @cqrt_free(i32 %h_op6), !dbg !37
  call void @cqrt_free(i32 %h_cmp), !dbg !39
    #dbg_value(i32 %h2, !19, !DIExpression(), !26)
  %h_op7 = call i32 @cq_template_add_i32(i32 %h4, i32 %h_cast), !dbg !41
  call void @cq_template_zext_i1_to_i32_unc(i32 %h_cast, i32 %h), !dbg !34
  call void @cqrt_free(i32 %h_cast), !dbg !34
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op7), !dbg !41
  %1 = add nsw i32 %m8, %m, !dbg !42
    #dbg_value(i32 %1, !20, !DIExpression(), !26)
  %m9 = call i32 @cqrt_measure_i32(i32 %h2), !dbg !43
  %2 = add nsw i32 %1, %m9, !dbg !44
  ret i32 %2, !dbg !45
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !46 {
  %1 = tail call i32 @slice(), !dbg !47
  ret i32 %1, !dbg !48
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

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_zext_i1_to_i32_unc(i32, i32)

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
!8 = !DIFile(filename: "d4_noRailRegion_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "772aff1bbe9b00e7553f2070592ec7f2")
!9 = !{!10, !11}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!12 = !{!"Homebrew clang version 19.1.7"}
!13 = distinct !DISubprogram(name: "slice", scope: !14, file: !14, line: 2, type: !15, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!14 = !DIFile(filename: "./d4_noRailRegion_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "772aff1bbe9b00e7553f2070592ec7f2")
!15 = !DISubroutineType(types: !16)
!16 = !{!11}
!17 = !{!18, !19, !20, !21, !23}
!18 = !DILocalVariable(name: "b", scope: !13, file: !14, line: 3, type: !10)
!19 = !DILocalVariable(name: "r", scope: !13, file: !14, line: 4, type: !11)
!20 = !DILocalVariable(name: "s", scope: !13, file: !14, line: 5, type: !11)
!21 = !DILocalVariable(name: "u", scope: !22, file: !14, line: 6, type: !11)
!22 = distinct !DILexicalBlock(scope: !13, file: !14, line: 6, column: 5)
!23 = !DILocalVariable(name: "u", scope: !24, file: !14, line: 7, type: !11)
!24 = distinct !DILexicalBlock(scope: !13, file: !14, line: 7, column: 5)
!25 = !DILocation(line: 3, column: 14, scope: !13)
!26 = !DILocation(line: 0, scope: !13)
!27 = !DILocation(line: 4, column: 13, scope: !13)
!28 = !DILocation(line: 6, column: 15, scope: !22)
!29 = !DILocation(line: 0, scope: !22)
!30 = !DILocation(line: 6, column: 46, scope: !31)
!31 = distinct !DILexicalBlock(scope: !22, file: !14, line: 6, column: 37)
!32 = !DILocation(line: 6, column: 37, scope: !22)
!33 = !DILocation(line: 6, column: 55, scope: !31)
!34 = !DILocation(line: 6, column: 78, scope: !22)
!35 = !DILocation(line: 7, column: 15, scope: !24)
!36 = !DILocation(line: 0, scope: !24)
!37 = !DILocation(line: 7, column: 46, scope: !38)
!38 = distinct !DILexicalBlock(scope: !24, file: !14, line: 7, column: 37)
!39 = !DILocation(line: 7, column: 37, scope: !24)
!40 = !DILocation(line: 7, column: 55, scope: !38)
!41 = !DILocation(line: 7, column: 78, scope: !24)
!42 = !DILocation(line: 7, column: 75, scope: !24)
!43 = !DILocation(line: 8, column: 16, scope: !13)
!44 = !DILocation(line: 8, column: 14, scope: !13)
!45 = !DILocation(line: 8, column: 5, scope: !13)
!46 = distinct !DISubprogram(name: "main", scope: !14, file: !14, line: 10, type: !15, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!47 = !DILocation(line: 10, column: 25, scope: !46)
!48 = !DILocation(line: 10, column: 18, scope: !46)
