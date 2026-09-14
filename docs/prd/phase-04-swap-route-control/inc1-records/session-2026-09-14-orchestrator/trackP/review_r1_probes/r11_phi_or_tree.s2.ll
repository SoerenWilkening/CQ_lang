; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r11_phi_or_tree.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r11_phi_or_tree.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !12 {
  %h1 = call i32 @cqrt_alloc_i32(i32 0), !dbg !20
  call void @cqrt_ry_i32(i32 %h1, double 0x3FE6666666666666), !dbg !20
    #dbg_value(i32 %h1, !17, !DIExpression(), !21)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !22
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !22
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
    #dbg_value(i8 0, !19, !DIExpression(), !21)
  %h2 = call i32 @cqrt_alloc_i1(i1 false), !dbg !23
  call void @cqrt_ry_i1_controlled(i32 %h, i32 %h2, double 5.000000e-01), !dbg !23
    #dbg_value(i8 poison, !19, !DIExpression(), !21)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h1, i32 3), !dbg !26
  %g = call i32 @cqrt_alloc_i1(i1 false), !dbg !28
  call void @cqrt_cnot(i32 %h2, i32 %g), !dbg !28
  call void @cqrt_cnot(i32 %h_cmp, i32 %g), !dbg !28
  call void @cqrt_toffoli(i32 %h2, i32 %h_cmp, i32 %g), !dbg !28
  call void @cqrt_rz_i1(i32 %g, double 3.000000e-01), !dbg !28, !cq.branchphase !29
  call void @cqrt_toffoli(i32 %h2, i32 %h_cmp, i32 %g), !dbg !28
  call void @cqrt_cnot(i32 %h_cmp, i32 %g), !dbg !28
  call void @cqrt_cnot(i32 %h2, i32 %g), !dbg !28
  call void @cqrt_free(i32 %g), !dbg !28
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h1, i32 3), !dbg !26
  call void @cqrt_free(i32 %h_cmp), !dbg !28
  %m = call i1 @cqrt_measure_i1(i32 %h), !dbg !30
  %1 = zext i1 %m to i32, !dbg !30
  %m3 = call i1 @cqrt_measure_i1(i32 %h2), !dbg !31
  %2 = zext i1 %m3 to i32, !dbg !31
  %3 = add nuw nsw i32 %2, %1, !dbg !32
  %m4 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !33
  %4 = add nsw i32 %3, %m4, !dbg !34
  ret i32 %4, !dbg !35
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_toffoli(i32, i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i1(i32, double)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i1_controlled(i32, i32, double)

declare i1 @cqrt_measure_i1(i32)

declare i32 @cqrt_measure_i32(i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r11_phi_or_tree.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "bfe0337df108e03ddd6ff94adc783088")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !13, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19}
!17 = !DILocalVariable(name: "q", scope: !12, file: !8, line: 4, type: !15)
!18 = !DILocalVariable(name: "b0", scope: !12, file: !8, line: 5, type: !10)
!19 = !DILocalVariable(name: "b1", scope: !12, file: !8, line: 6, type: !10)
!20 = !DILocation(line: 4, column: 13, scope: !12)
!21 = !DILocation(line: 0, scope: !12)
!22 = !DILocation(line: 5, column: 15, scope: !12)
!23 = !DILocation(line: 7, column: 20, scope: !24)
!24 = distinct !DILexicalBlock(scope: !25, file: !8, line: 7, column: 13)
!25 = distinct !DILexicalBlock(scope: !12, file: !8, line: 7, column: 9)
!26 = !DILocation(line: 8, column: 12, scope: !27)
!27 = distinct !DILexicalBlock(scope: !12, file: !8, line: 8, column: 9)
!28 = !DILocation(line: 8, column: 22, scope: !27)
!29 = !{}
!30 = !DILocation(line: 9, column: 12, scope: !12)
!31 = !DILocation(line: 9, column: 29, scope: !12)
!32 = !DILocation(line: 9, column: 27, scope: !12)
!33 = !DILocation(line: 9, column: 46, scope: !12)
!34 = !DILocation(line: 9, column: 44, scope: !12)
!35 = !DILocation(line: 9, column: 5, scope: !12)
