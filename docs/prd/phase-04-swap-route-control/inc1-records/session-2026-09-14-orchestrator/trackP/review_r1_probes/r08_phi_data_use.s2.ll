; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r08_phi_data_use.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r08_phi_data_use.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !13 {
  %h1 = call i32 @cqrt_alloc_i32(i32 0), !dbg !21
  call void @cqrt_ry_i32(i32 %h1, double 0x3FE6666666666666), !dbg !21
    #dbg_value(i32 %h1, !17, !DIExpression(), !22)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !23
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !23
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i8 0, !19, !DIExpression(), !22)
  %h2 = call i32 @cqrt_alloc_i1(i1 false), !dbg !24
  call void @cqrt_ry_i1_controlled(i32 %h, i32 %h2, double 5.000000e-01), !dbg !24
    #dbg_value(i8 poison, !19, !DIExpression(), !22)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h1, i32 3), !dbg !27
  %g = call i32 @cqrt_alloc_i1(i1 false), !dbg !29
  call void @cqrt_toffoli(i32 %h2, i32 %h_cmp, i32 %g), !dbg !29
  call void @cqrt_rz_i1(i32 %g, double 3.000000e-01), !dbg !29, !cq.branchphase !30
  call void @cqrt_toffoli(i32 %h2, i32 %h_cmp, i32 %g), !dbg !29
  call void @cqrt_free(i32 %g), !dbg !29
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h1, i32 3), !dbg !27
  call void @cqrt_free(i32 %h_cmp), !dbg !29
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h2), !dbg !31
  %h_op = call i32 @cq_template_add_i32(i32 %h1, i32 %h_cast), !dbg !32
    #dbg_value(i32 %h_op, !20, !DIExpression(), !22)
  call void @cq_template_zext_i1_to_i32_unc(i32 %h_cast, i32 %h2), !dbg !31
  call void @cqrt_free(i32 %h_cast), !dbg !31
  %m = call i1 @cqrt_measure_i1(i32 %h), !dbg !33
  %1 = zext i1 %m to i32, !dbg !33
  %m3 = call i1 @cqrt_measure_i1(i32 %h2), !dbg !34
  %2 = zext i1 %m3 to i32, !dbg !34
  %3 = add nuw nsw i32 %2, %1, !dbg !35
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !36
  %4 = add nsw i32 %3, %m4, !dbg !37
  ret i32 %4, !dbg !38
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_toffoli(i32, i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i1(i32, double)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i1_controlled(i32, i32, double)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i1 @cqrt_measure_i1(i32)

declare i32 @cqrt_measure_i32(i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r08_phi_data_use.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "489ba4b9675bc928e73517437b6d6768")
!9 = !{!10, !11}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!12 = !{!"Homebrew clang version 19.1.7"}
!13 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 6, type: !14, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!14 = !DISubroutineType(types: !15)
!15 = !{!11}
!16 = !{!17, !18, !19, !20}
!17 = !DILocalVariable(name: "q", scope: !13, file: !8, line: 7, type: !11)
!18 = !DILocalVariable(name: "b0", scope: !13, file: !8, line: 8, type: !10)
!19 = !DILocalVariable(name: "b1", scope: !13, file: !8, line: 9, type: !10)
!20 = !DILocalVariable(name: "z", scope: !13, file: !8, line: 12, type: !11)
!21 = !DILocation(line: 7, column: 13, scope: !13)
!22 = !DILocation(line: 0, scope: !13)
!23 = !DILocation(line: 8, column: 15, scope: !13)
!24 = !DILocation(line: 10, column: 20, scope: !25)
!25 = distinct !DILexicalBlock(scope: !26, file: !8, line: 10, column: 13)
!26 = distinct !DILexicalBlock(scope: !13, file: !8, line: 10, column: 9)
!27 = !DILocation(line: 11, column: 12, scope: !28)
!28 = distinct !DILexicalBlock(scope: !13, file: !8, line: 11, column: 9)
!29 = !DILocation(line: 11, column: 22, scope: !28)
!30 = !{}
!31 = !DILocation(line: 12, column: 13, scope: !13)
!32 = !DILocation(line: 12, column: 21, scope: !13)
!33 = !DILocation(line: 13, column: 12, scope: !13)
!34 = !DILocation(line: 13, column: 29, scope: !13)
!35 = !DILocation(line: 13, column: 27, scope: !13)
!36 = !DILocation(line: 13, column: 46, scope: !13)
!37 = !DILocation(line: 13, column: 44, scope: !13)
!38 = !DILocation(line: 13, column: 5, scope: !13)
