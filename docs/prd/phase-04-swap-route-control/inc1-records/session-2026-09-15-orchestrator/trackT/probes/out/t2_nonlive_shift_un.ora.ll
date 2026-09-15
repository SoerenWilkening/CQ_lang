; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/out/t2_nonlive_shift_un.ora.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t2_nonlive_shift_un.c"
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
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !20
  %1 = add nsw i32 %m4, %m, !dbg !21
    #dbg_value(i32 %1, !16, !DIExpression(), !18)
  %m5 = call i32 @cqrt_measure_i32(i32 %h), !dbg !22
  %2 = add nsw i32 %1, %m5, !dbg !23
  ret i32 %2, !dbg !24
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !25 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !26
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !26
    #dbg_value(i32 %h, !15, !DIExpression(), !28)
    #dbg_value(i32 0, !16, !DIExpression(), !28)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !29
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !29
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !29
  call void @cqrt_free(i32 %h_op), !dbg !29
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !29
    #dbg_value(i32 %m, !16, !DIExpression(), !28)
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 2), !dbg !30
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 1), !dbg !30
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op2, i32 %h, i32 2), !dbg !30
  call void @cqrt_free(i32 %h_op2), !dbg !30
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !30
  %1 = add nsw i32 %m4, %m, !dbg !31
    #dbg_value(i32 %1, !16, !DIExpression(), !28)
  %m5 = call i32 @cqrt_measure_i32(i32 %h), !dbg !32
  %2 = add nsw i32 %1, %m5, !dbg !33
  ret i32 %2, !dbg !34
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t2_nonlive_shift_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "b6232af7709449d91f8187f25d87f407")
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
!22 = !DILocation(line: 8, column: 16, scope: !10)
!23 = !DILocation(line: 8, column: 14, scope: !10)
!24 = !DILocation(line: 8, column: 5, scope: !10)
!25 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!26 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !27)
!27 = distinct !DILocation(line: 10, column: 25, scope: !25)
!28 = !DILocation(line: 0, scope: !10, inlinedAt: !27)
!29 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !27)
!30 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !27)
!31 = !DILocation(line: 7, column: 7, scope: !10, inlinedAt: !27)
!32 = !DILocation(line: 8, column: 16, scope: !10, inlinedAt: !27)
!33 = !DILocation(line: 8, column: 14, scope: !10, inlinedAt: !27)
!34 = !DILocation(line: 10, column: 18, scope: !25)
