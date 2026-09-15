; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/out/s2_live_derived_region_un.ora.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/s2_live_derived_region_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !18
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !18
    #dbg_value(i32 %h, !15, !DIExpression(), !19)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3), !dbg !20
    #dbg_value(i32 %h_op, !16, !DIExpression(), !19)
    #dbg_value(i32 0, !17, !DIExpression(), !19)
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 2), !dbg !21
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op2, i32 0), !dbg !21
  call void @cqrt_x(i32 %h_cmp1), !dbg !23
  call void @cqrt_rz_i1(i32 %h_cmp1, double 3.000000e-01), !dbg !23, !cq.branchphase !24
  call void @cqrt_x(i32 %h_cmp1), !dbg !23
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op2, i32 0), !dbg !21
  call void @cqrt_free(i32 %h_cmp1), !dbg !23
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 4), !dbg !25
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op3, i32 0), !dbg !25
  call void @cqrt_x(i32 %h_cmp), !dbg !27
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01), !dbg !27, !cq.branchphase !24
  call void @cqrt_x(i32 %h_cmp), !dbg !27
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op3, i32 0), !dbg !25
  call void @cq_template_and_i32_hl_unc(i32 %h_op3, i32 %h_op, i32 4), !dbg !25
  call void @cqrt_free(i32 %h_op3), !dbg !25
  call void @cq_template_and_i32_hl_unc(i32 %h_op2, i32 %h_op, i32 2), !dbg !21
  call void @cqrt_free(i32 %h_op2), !dbg !21
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3), !dbg !20
  call void @cqrt_free(i32 %h_op), !dbg !20
  call void @cqrt_free(i32 %h_cmp), !dbg !27
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !28
    #dbg_value(i32 %h, !15, !DIExpression(), !19)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !29
  ret i32 %m, !dbg !30
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !31 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !32
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !32
    #dbg_value(i32 %h, !15, !DIExpression(), !34)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3), !dbg !35
    #dbg_value(i32 %h_op, !16, !DIExpression(), !34)
    #dbg_value(i32 0, !17, !DIExpression(), !34)
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 2), !dbg !36
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op2, i32 0), !dbg !36
  call void @cqrt_x(i32 %h_cmp1), !dbg !37
  call void @cqrt_rz_i1(i32 %h_cmp1, double 3.000000e-01), !dbg !37, !cq.branchphase !24
  call void @cqrt_x(i32 %h_cmp1), !dbg !37
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op2, i32 0), !dbg !36
  call void @cqrt_free(i32 %h_cmp1), !dbg !37
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 4), !dbg !38
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op3, i32 0), !dbg !38
  call void @cqrt_x(i32 %h_cmp), !dbg !39
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01), !dbg !39, !cq.branchphase !24
  call void @cqrt_x(i32 %h_cmp), !dbg !39
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op3, i32 0), !dbg !38
  call void @cq_template_and_i32_hl_unc(i32 %h_op3, i32 %h_op, i32 4), !dbg !38
  call void @cqrt_free(i32 %h_op3), !dbg !38
  call void @cq_template_and_i32_hl_unc(i32 %h_op2, i32 %h_op, i32 2), !dbg !36
  call void @cqrt_free(i32 %h_op2), !dbg !36
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3), !dbg !35
  call void @cqrt_free(i32 %h_op), !dbg !35
  call void @cqrt_free(i32 %h_cmp), !dbg !39
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !40
    #dbg_value(i32 %h, !15, !DIExpression(), !34)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !41
  ret i32 %m, !dbg !42
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/s2_live_derived_region_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "0fe4aac5f33fc8c44f6be61e27188839")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "p", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 6, type: !13)
!18 = !DILocation(line: 4, column: 13, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 5, column: 15, scope: !10)
!21 = !DILocation(line: 7, column: 18, scope: !22)
!22 = distinct !DILexicalBlock(scope: !10, file: !8, line: 7, column: 9)
!23 = !DILocation(line: 7, column: 23, scope: !22)
!24 = !{}
!25 = !DILocation(line: 8, column: 18, scope: !26)
!26 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 9)
!27 = !DILocation(line: 8, column: 23, scope: !26)
!28 = !DILocation(line: 9, column: 9, scope: !10)
!29 = !DILocation(line: 10, column: 16, scope: !10)
!30 = !DILocation(line: 10, column: 5, scope: !10)
!31 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 12, type: !11, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!32 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !33)
!33 = distinct !DILocation(line: 12, column: 25, scope: !31)
!34 = !DILocation(line: 0, scope: !10, inlinedAt: !33)
!35 = !DILocation(line: 5, column: 15, scope: !10, inlinedAt: !33)
!36 = !DILocation(line: 7, column: 18, scope: !22, inlinedAt: !33)
!37 = !DILocation(line: 7, column: 23, scope: !22, inlinedAt: !33)
!38 = !DILocation(line: 8, column: 18, scope: !26, inlinedAt: !33)
!39 = !DILocation(line: 8, column: 23, scope: !26, inlinedAt: !33)
!40 = !DILocation(line: 9, column: 9, scope: !10, inlinedAt: !33)
!41 = !DILocation(line: 10, column: 16, scope: !10, inlinedAt: !33)
!42 = !DILocation(line: 12, column: 18, scope: !31)
