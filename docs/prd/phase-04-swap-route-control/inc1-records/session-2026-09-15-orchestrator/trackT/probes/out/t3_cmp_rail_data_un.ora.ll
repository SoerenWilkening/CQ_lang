; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/out/t3_cmp_rail_data_un.ora.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t3_cmp_rail_data_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !17
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !17
    #dbg_value(i32 %h, !15, !DIExpression(), !18)
    #dbg_value(i32 0, !16, !DIExpression(), !18)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 -2), !dbg !19
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 2), !dbg !19
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp), !dbg !19
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 2), !dbg !19
  call void @cqrt_free(i32 %h_cmp), !dbg !19
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 -2), !dbg !19
  call void @cqrt_free(i32 %h_op), !dbg !19
  %m = call i32 @cqrt_measure_i32(i32 %h_cast), !dbg !19
    #dbg_value(i32 %m, !16, !DIExpression(), !18)
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h, i32 -4), !dbg !20
  %h_cmp2 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 4), !dbg !20
  %h_cast3 = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp2), !dbg !20
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp2, i32 %h_op1, i32 4), !dbg !20
  call void @cqrt_free(i32 %h_cmp2), !dbg !20
  call void @cq_template_and_i32_hl_unc(i32 %h_op1, i32 %h, i32 -4), !dbg !20
  call void @cqrt_free(i32 %h_op1), !dbg !20
  %m4 = call i32 @cqrt_measure_i32(i32 %h_cast3), !dbg !20
  %1 = add nsw i32 %m4, %m, !dbg !21
    #dbg_value(i32 %1, !16, !DIExpression(), !18)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !22
    #dbg_value(i32 %h, !15, !DIExpression(), !18)
  %m5 = call i32 @cqrt_measure_i32(i32 %h), !dbg !23
  %2 = add nsw i32 %1, %m5, !dbg !24
  ret i32 %2, !dbg !25
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !26 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !27
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !27
    #dbg_value(i32 %h, !15, !DIExpression(), !29)
    #dbg_value(i32 0, !16, !DIExpression(), !29)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 -2), !dbg !30
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 2), !dbg !30
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp), !dbg !30
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 2), !dbg !30
  call void @cqrt_free(i32 %h_cmp), !dbg !30
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 -2), !dbg !30
  call void @cqrt_free(i32 %h_op), !dbg !30
  %m = call i32 @cqrt_measure_i32(i32 %h_cast), !dbg !30
    #dbg_value(i32 %m, !16, !DIExpression(), !29)
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h, i32 -4), !dbg !31
  %h_cmp2 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 4), !dbg !31
  %h_cast3 = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp2), !dbg !31
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp2, i32 %h_op1, i32 4), !dbg !31
  call void @cqrt_free(i32 %h_cmp2), !dbg !31
  call void @cq_template_and_i32_hl_unc(i32 %h_op1, i32 %h, i32 -4), !dbg !31
  call void @cqrt_free(i32 %h_op1), !dbg !31
  %m4 = call i32 @cqrt_measure_i32(i32 %h_cast3), !dbg !31
  %1 = add nsw i32 %m4, %m, !dbg !32
    #dbg_value(i32 %1, !16, !DIExpression(), !29)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !33
    #dbg_value(i32 %h, !15, !DIExpression(), !29)
  %m5 = call i32 @cqrt_measure_i32(i32 %h), !dbg !34
  %2 = add nsw i32 %1, %m5, !dbg !35
  ret i32 %2, !dbg !36
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t3_cmp_rail_data_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "eb39f1cc3334ab94753864bb6b35a677")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocation(line: 4, column: 13, scope: !10)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 6, column: 10, scope: !10)
!20 = !DILocation(line: 7, column: 10, scope: !10)
!21 = !DILocation(line: 7, column: 7, scope: !10)
!22 = !DILocation(line: 8, column: 9, scope: !10)
!23 = !DILocation(line: 9, column: 16, scope: !10)
!24 = !DILocation(line: 9, column: 14, scope: !10)
!25 = !DILocation(line: 9, column: 5, scope: !10)
!26 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !11, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!27 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !28)
!28 = distinct !DILocation(line: 11, column: 25, scope: !26)
!29 = !DILocation(line: 0, scope: !10, inlinedAt: !28)
!30 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !28)
!31 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !28)
!32 = !DILocation(line: 7, column: 7, scope: !10, inlinedAt: !28)
!33 = !DILocation(line: 8, column: 9, scope: !10, inlinedAt: !28)
!34 = !DILocation(line: 9, column: 16, scope: !10, inlinedAt: !28)
!35 = !DILocation(line: 9, column: 14, scope: !10, inlinedAt: !28)
!36 = !DILocation(line: 11, column: 18, scope: !26)
