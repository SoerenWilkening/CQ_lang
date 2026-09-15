; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/a9_nested_loop_un.ora.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a9_nested_loop_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !17
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !17
    #dbg_value(i32 %h, !15, !DIExpression(), !18)
    #dbg_value(i32 0, !16, !DIExpression(), !18)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !19
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !19
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !19
  call void @cqrt_free(i32 %h_op), !dbg !19
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !19
    #dbg_value(i32 %m, !16, !DIExpression(), !18)
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 2), !dbg !20
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 1), !dbg !20
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op2, i32 %h, i32 2), !dbg !20
  call void @cqrt_free(i32 %h_op2), !dbg !20
  %m6 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !20
  %1 = add nsw i32 %m6, %m, !dbg !21
    #dbg_value(i32 %1, !16, !DIExpression(), !18)
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !22
  %2 = add nsw i32 %1, %m7, !dbg !23
    #dbg_value(i32 %2, !16, !DIExpression(), !18)
  %h_op4 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 3), !dbg !24
  %h_op5 = call i32 @cq_template_and_i32_hl(i32 %h_op4, i32 1), !dbg !24
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op4, i32 %h, i32 3), !dbg !24
  call void @cqrt_free(i32 %h_op4), !dbg !24
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op5), !dbg !24
  %3 = add nsw i32 %2, %m8, !dbg !25
    #dbg_value(i32 %3, !16, !DIExpression(), !18)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !26
    #dbg_value(i32 %h, !15, !DIExpression(), !18)
  %m9 = call i32 @cqrt_measure_i32(i32 %h), !dbg !27
  %4 = add nsw i32 %3, %m9, !dbg !28
  ret i32 %4, !dbg !29
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !30 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !31
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !31
    #dbg_value(i32 %h, !15, !DIExpression(), !33)
    #dbg_value(i32 0, !16, !DIExpression(), !33)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !34
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !34
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !34
  call void @cqrt_free(i32 %h_op), !dbg !34
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !34
    #dbg_value(i32 %m, !16, !DIExpression(), !33)
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 2), !dbg !35
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 1), !dbg !35
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op2, i32 %h, i32 2), !dbg !35
  call void @cqrt_free(i32 %h_op2), !dbg !35
  %m6 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !35
  %1 = add nsw i32 %m6, %m, !dbg !36
    #dbg_value(i32 %1, !16, !DIExpression(), !33)
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !37
  %2 = add nsw i32 %1, %m7, !dbg !38
    #dbg_value(i32 %2, !16, !DIExpression(), !33)
  %h_op4 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 3), !dbg !39
  %h_op5 = call i32 @cq_template_and_i32_hl(i32 %h_op4, i32 1), !dbg !39
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op4, i32 %h, i32 3), !dbg !39
  call void @cqrt_free(i32 %h_op4), !dbg !39
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op5), !dbg !39
  %3 = add nsw i32 %2, %m8, !dbg !40
    #dbg_value(i32 %3, !16, !DIExpression(), !33)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !41
    #dbg_value(i32 %h, !15, !DIExpression(), !33)
  %m9 = call i32 @cqrt_measure_i32(i32 %h), !dbg !42
  %4 = add nsw i32 %3, %m9, !dbg !43
  ret i32 %4, !dbg !44
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a9_nested_loop_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "27129ff9f3b4a0bda9fac5863f4ba620")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocation(line: 3, column: 13, scope: !10)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 5, column: 10, scope: !10)
!20 = !DILocation(line: 6, column: 10, scope: !10)
!21 = !DILocation(line: 6, column: 7, scope: !10)
!22 = !DILocation(line: 7, column: 10, scope: !10)
!23 = !DILocation(line: 7, column: 7, scope: !10)
!24 = !DILocation(line: 8, column: 10, scope: !10)
!25 = !DILocation(line: 8, column: 7, scope: !10)
!26 = !DILocation(line: 9, column: 9, scope: !10)
!27 = !DILocation(line: 10, column: 16, scope: !10)
!28 = !DILocation(line: 10, column: 14, scope: !10)
!29 = !DILocation(line: 10, column: 5, scope: !10)
!30 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 12, type: !11, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!31 = !DILocation(line: 3, column: 13, scope: !10, inlinedAt: !32)
!32 = distinct !DILocation(line: 12, column: 25, scope: !30)
!33 = !DILocation(line: 0, scope: !10, inlinedAt: !32)
!34 = !DILocation(line: 5, column: 10, scope: !10, inlinedAt: !32)
!35 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !32)
!36 = !DILocation(line: 6, column: 7, scope: !10, inlinedAt: !32)
!37 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !32)
!38 = !DILocation(line: 7, column: 7, scope: !10, inlinedAt: !32)
!39 = !DILocation(line: 8, column: 10, scope: !10, inlinedAt: !32)
!40 = !DILocation(line: 8, column: 7, scope: !10, inlinedAt: !32)
!41 = !DILocation(line: 9, column: 9, scope: !10, inlinedAt: !32)
!42 = !DILocation(line: 10, column: 16, scope: !10, inlinedAt: !32)
!43 = !DILocation(line: 10, column: 14, scope: !10, inlinedAt: !32)
!44 = !DILocation(line: 12, column: 18, scope: !30)
