; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/a4_invariant_measured_and_read_after_un.ora.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a4_invariant_measured_and_read_after_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !18
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !18
    #dbg_value(i32 %h, !15, !DIExpression(), !19)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !20
    #dbg_value(i32 %h_op, !16, !DIExpression(), !19)
    #dbg_value(i32 0, !17, !DIExpression(), !19)
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !21
  %h_op1 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !22
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op1, i32 1), !dbg !22
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op1, i32 %h, i32 1), !dbg !22
  call void @cqrt_free(i32 %h_op1), !dbg !22
  %m6 = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !22
    #dbg_value(i32 poison, !17, !DIExpression(), !19)
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !23
  %h_op3 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 2), !dbg !24
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h_op3, i32 1), !dbg !24
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op3, i32 %h, i32 2), !dbg !24
  call void @cqrt_free(i32 %h_op3), !dbg !24
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !24
    #dbg_value(i32 %3, !17, !DIExpression(), !19)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !25
    #dbg_value(i32 %h, !15, !DIExpression(), !19)
  %h_op5 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 1), !dbg !26
  %m9 = call i32 @cqrt_measure_i32(i32 %h_op5), !dbg !26
  %m10 = call i32 @cqrt_measure_i32(i32 %h), !dbg !27
  %1 = add i32 %m6, %m, !dbg !28
  %2 = add i32 %1, %m7, !dbg !29
  %3 = add i32 %2, %m8, !dbg !30
  %4 = add nsw i32 %3, %m9, !dbg !31
  %5 = add nsw i32 %4, %m10, !dbg !32
  ret i32 %5, !dbg !33
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !34 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !35
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !35
    #dbg_value(i32 %h, !15, !DIExpression(), !37)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !38
    #dbg_value(i32 %h_op, !16, !DIExpression(), !37)
    #dbg_value(i32 0, !17, !DIExpression(), !37)
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !39
  %h_op1 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !40
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op1, i32 1), !dbg !40
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op1, i32 %h, i32 1), !dbg !40
  call void @cqrt_free(i32 %h_op1), !dbg !40
  %m6 = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !40
    #dbg_value(i32 poison, !17, !DIExpression(), !37)
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !41
  %h_op3 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 2), !dbg !42
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h_op3, i32 1), !dbg !42
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op3, i32 %h, i32 2), !dbg !42
  call void @cqrt_free(i32 %h_op3), !dbg !42
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !42
    #dbg_value(i32 %3, !17, !DIExpression(), !37)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !43
    #dbg_value(i32 %h, !15, !DIExpression(), !37)
  %h_op5 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 1), !dbg !44
  %m9 = call i32 @cqrt_measure_i32(i32 %h_op5), !dbg !44
  %m10 = call i32 @cqrt_measure_i32(i32 %h), !dbg !45
  %1 = add i32 %m6, %m, !dbg !46
  %2 = add i32 %1, %m7, !dbg !47
  %3 = add i32 %2, %m8, !dbg !48
  %4 = add nsw i32 %3, %m9, !dbg !49
  %5 = add nsw i32 %4, %m10, !dbg !50
  ret i32 %5, !dbg !51
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a4_invariant_measured_and_read_after_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "360f96945f69461dbc80c062847a7665")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!18 = !DILocation(line: 3, column: 13, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 4, column: 15, scope: !10)
!21 = !DILocation(line: 6, column: 10, scope: !10)
!22 = !DILocation(line: 6, column: 26, scope: !10)
!23 = !DILocation(line: 7, column: 10, scope: !10)
!24 = !DILocation(line: 7, column: 26, scope: !10)
!25 = !DILocation(line: 8, column: 9, scope: !10)
!26 = !DILocation(line: 9, column: 16, scope: !10)
!27 = !DILocation(line: 9, column: 36, scope: !10)
!28 = !DILocation(line: 7, column: 24, scope: !10)
!29 = !DILocation(line: 6, column: 24, scope: !10)
!30 = !DILocation(line: 7, column: 7, scope: !10)
!31 = !DILocation(line: 9, column: 14, scope: !10)
!32 = !DILocation(line: 9, column: 34, scope: !10)
!33 = !DILocation(line: 9, column: 5, scope: !10)
!34 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !11, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!35 = !DILocation(line: 3, column: 13, scope: !10, inlinedAt: !36)
!36 = distinct !DILocation(line: 11, column: 25, scope: !34)
!37 = !DILocation(line: 0, scope: !10, inlinedAt: !36)
!38 = !DILocation(line: 4, column: 15, scope: !10, inlinedAt: !36)
!39 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !36)
!40 = !DILocation(line: 6, column: 26, scope: !10, inlinedAt: !36)
!41 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !36)
!42 = !DILocation(line: 7, column: 26, scope: !10, inlinedAt: !36)
!43 = !DILocation(line: 8, column: 9, scope: !10, inlinedAt: !36)
!44 = !DILocation(line: 9, column: 16, scope: !10, inlinedAt: !36)
!45 = !DILocation(line: 9, column: 36, scope: !10, inlinedAt: !36)
!46 = !DILocation(line: 7, column: 24, scope: !10, inlinedAt: !36)
!47 = !DILocation(line: 6, column: 24, scope: !10, inlinedAt: !36)
!48 = !DILocation(line: 7, column: 7, scope: !10, inlinedAt: !36)
!49 = !DILocation(line: 9, column: 14, scope: !10, inlinedAt: !36)
!50 = !DILocation(line: 9, column: 34, scope: !10, inlinedAt: !36)
!51 = !DILocation(line: 11, column: 18, scope: !34)
