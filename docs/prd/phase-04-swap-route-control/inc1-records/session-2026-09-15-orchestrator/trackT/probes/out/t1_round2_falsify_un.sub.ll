; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/out/t1_round2_falsify_un.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t1_round2_falsify_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !19
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !19
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !21
  call void @cqrt_ry_i32(i32 %h2, double 3.000000e-01), !dbg !21
    #dbg_value(i32 %h2, !16, !DIExpression(), !20)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !22
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !22
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %selop1 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 0), !dbg !22
  call void @cqrt_free(i32 %h_cmp)
    #dbg_value(i32 %out, !17, !DIExpression(), !20)
    #dbg_value(i32 0, !18, !DIExpression(), !20)
  %h_op3 = call i32 @cq_template_lshr_i32_hl(i32 %h2, i32 1), !dbg !24
  %h_op4 = call i32 @cq_template_and_i32(i32 %out, i32 %h_op3), !dbg !24
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op3, i32 %h2, i32 1), !dbg !24
  call void @cqrt_free(i32 %h_op3), !dbg !24
  %m = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !24
    #dbg_value(i32 %m, !18, !DIExpression(), !20)
  %h_op5 = call i32 @cq_template_lshr_i32_hl(i32 %h2, i32 2), !dbg !25
  %h_op6 = call i32 @cq_template_and_i32(i32 %out, i32 %h_op5), !dbg !25
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op5, i32 %h2, i32 2), !dbg !25
  call void @cqrt_free(i32 %h_op5), !dbg !25
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op6), !dbg !25
  %1 = add nsw i32 %m7, %m, !dbg !26
    #dbg_value(i32 %1, !18, !DIExpression(), !20)
  call void @cqrt_ry_i32(i32 %h2, double 9.000000e-01), !dbg !27
    #dbg_value(i32 %h2, !16, !DIExpression(), !20)
  %m8 = call i32 @cqrt_measure_i32(i32 %h2), !dbg !28
  %2 = add nsw i32 %1, %m8, !dbg !29
  %m9 = call i32 @cqrt_measure_i32(i32 %h), !dbg !30
  %3 = add nsw i32 %2, %m9, !dbg !31
  ret i32 %3, !dbg !32
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !33 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !34
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !34
    #dbg_value(i32 %h, !15, !DIExpression(), !36)
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !37
  call void @cqrt_ry_i32(i32 %h2, double 3.000000e-01), !dbg !37
    #dbg_value(i32 %h2, !16, !DIExpression(), !36)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !38
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !38
  %out = call i32 @cqrt_alloc_i32(i32 0)
  %selop = call i32 @cqrt_alloc_i32(i32 5)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %selop1 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 0), !dbg !38
  call void @cqrt_free(i32 %h_cmp)
    #dbg_value(i32 %out, !17, !DIExpression(), !36)
    #dbg_value(i32 0, !18, !DIExpression(), !36)
  %h_op3 = call i32 @cq_template_lshr_i32_hl(i32 %h2, i32 1), !dbg !39
  %h_op4 = call i32 @cq_template_and_i32(i32 %out, i32 %h_op3), !dbg !39
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op3, i32 %h2, i32 1), !dbg !39
  call void @cqrt_free(i32 %h_op3), !dbg !39
  %m = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !39
    #dbg_value(i32 %m, !18, !DIExpression(), !36)
  %h_op5 = call i32 @cq_template_lshr_i32_hl(i32 %h2, i32 2), !dbg !40
  %h_op6 = call i32 @cq_template_and_i32(i32 %out, i32 %h_op5), !dbg !40
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op5, i32 %h2, i32 2), !dbg !40
  call void @cqrt_free(i32 %h_op5), !dbg !40
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op6), !dbg !40
  %1 = add nsw i32 %m7, %m, !dbg !41
    #dbg_value(i32 %1, !18, !DIExpression(), !36)
  call void @cqrt_ry_i32(i32 %h2, double 9.000000e-01), !dbg !42
    #dbg_value(i32 %h2, !16, !DIExpression(), !36)
  %m8 = call i32 @cqrt_measure_i32(i32 %h2), !dbg !43
  %2 = add nsw i32 %1, %m8, !dbg !44
  %m9 = call i32 @cqrt_measure_i32(i32 %h), !dbg !45
  %3 = add nsw i32 %2, %m9, !dbg !46
  ret i32 %3, !dbg !47
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t1_round2_falsify_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "9975ab0974a2c1fc6c0490ef21235551")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 6, type: !13)
!18 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!19 = !DILocation(line: 4, column: 13, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 5, column: 13, scope: !10)
!22 = !DILocation(line: 7, column: 11, scope: !23)
!23 = distinct !DILexicalBlock(scope: !10, file: !8, line: 7, column: 9)
!24 = !DILocation(line: 9, column: 10, scope: !10)
!25 = !DILocation(line: 10, column: 10, scope: !10)
!26 = !DILocation(line: 10, column: 7, scope: !10)
!27 = !DILocation(line: 11, column: 9, scope: !10)
!28 = !DILocation(line: 12, column: 16, scope: !10)
!29 = !DILocation(line: 12, column: 14, scope: !10)
!30 = !DILocation(line: 12, column: 32, scope: !10)
!31 = !DILocation(line: 12, column: 30, scope: !10)
!32 = !DILocation(line: 12, column: 5, scope: !10)
!33 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 14, type: !11, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!34 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !35)
!35 = distinct !DILocation(line: 14, column: 25, scope: !33)
!36 = !DILocation(line: 0, scope: !10, inlinedAt: !35)
!37 = !DILocation(line: 5, column: 13, scope: !10, inlinedAt: !35)
!38 = !DILocation(line: 7, column: 11, scope: !23, inlinedAt: !35)
!39 = !DILocation(line: 9, column: 10, scope: !10, inlinedAt: !35)
!40 = !DILocation(line: 10, column: 10, scope: !10, inlinedAt: !35)
!41 = !DILocation(line: 10, column: 7, scope: !10, inlinedAt: !35)
!42 = !DILocation(line: 11, column: 9, scope: !10, inlinedAt: !35)
!43 = !DILocation(line: 12, column: 16, scope: !10, inlinedAt: !35)
!44 = !DILocation(line: 12, column: 14, scope: !10, inlinedAt: !35)
!45 = !DILocation(line: 12, column: 32, scope: !10, inlinedAt: !35)
!46 = !DILocation(line: 12, column: 30, scope: !10, inlinedAt: !35)
!47 = !DILocation(line: 14, column: 18, scope: !33)
