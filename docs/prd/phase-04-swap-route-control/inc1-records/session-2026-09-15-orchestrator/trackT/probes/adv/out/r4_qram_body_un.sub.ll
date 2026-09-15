; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/r4_qram_body_un.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r4_qram_body_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.slice.tbl = private unnamed_addr constant [8 x i32] [i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
    #dbg_declare(ptr @__const.slice.tbl, !15, !DIExpression(), !21)
  %arr = call i32 @cqrt_qram_alloc_i32(i32 8), !dbg !22
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !23
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !23
    #dbg_value(i32 %h, !19, !DIExpression(), !24)
    #dbg_value(i32 0, !20, !DIExpression(), !24)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !22
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 7), !dbg !22
  %1 = call i32 @cqrt_qram_load_i32(i32 %arr, i32 %h_op1), !dbg !22
  call void @cq_template_and_i32_hl_unc(i32 %h_op1, i32 %h_op, i32 7), !dbg !22
  call void @cqrt_free(i32 %h_op1), !dbg !22
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !22
  call void @cqrt_free(i32 %h_op), !dbg !22
  %m = call i32 @cqrt_measure_i32(i32 %1), !dbg !22
    #dbg_value(i32 %m, !20, !DIExpression(), !24)
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 2), !dbg !25
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 7), !dbg !25
  %2 = call i32 @cqrt_qram_load_i32(i32 %arr, i32 %h_op3), !dbg !25
  call void @cq_template_and_i32_hl_unc(i32 %h_op3, i32 %h_op2, i32 7), !dbg !25
  call void @cqrt_free(i32 %h_op3), !dbg !25
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op2, i32 %h, i32 2), !dbg !25
  call void @cqrt_free(i32 %h_op2), !dbg !25
  %m4 = call i32 @cqrt_measure_i32(i32 %2), !dbg !25
  %3 = add nsw i32 %m4, %m, !dbg !26
    #dbg_value(i32 %3, !20, !DIExpression(), !24)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !27
    #dbg_value(i32 %h, !19, !DIExpression(), !24)
  %m5 = call i32 @cqrt_measure_i32(i32 %h), !dbg !28
  %4 = add nsw i32 %3, %m5, !dbg !29
  ret i32 %4, !dbg !30
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !31 {
    #dbg_declare(ptr @__const.slice.tbl, !15, !DIExpression(), !32)
  %arr = call i32 @cqrt_qram_alloc_i32(i32 8), !dbg !34
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !35
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !35
    #dbg_value(i32 %h, !19, !DIExpression(), !36)
    #dbg_value(i32 0, !20, !DIExpression(), !36)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !34
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 7), !dbg !34
  %1 = call i32 @cqrt_qram_load_i32(i32 %arr, i32 %h_op1), !dbg !34
  call void @cq_template_and_i32_hl_unc(i32 %h_op1, i32 %h_op, i32 7), !dbg !34
  call void @cqrt_free(i32 %h_op1), !dbg !34
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !34
  call void @cqrt_free(i32 %h_op), !dbg !34
  %m = call i32 @cqrt_measure_i32(i32 %1), !dbg !34
    #dbg_value(i32 %m, !20, !DIExpression(), !36)
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 2), !dbg !37
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 7), !dbg !37
  %2 = call i32 @cqrt_qram_load_i32(i32 %arr, i32 %h_op3), !dbg !37
  call void @cq_template_and_i32_hl_unc(i32 %h_op3, i32 %h_op2, i32 7), !dbg !37
  call void @cqrt_free(i32 %h_op3), !dbg !37
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op2, i32 %h, i32 2), !dbg !37
  call void @cqrt_free(i32 %h_op2), !dbg !37
  %m4 = call i32 @cqrt_measure_i32(i32 %2), !dbg !37
  %3 = add nsw i32 %m4, %m, !dbg !38
    #dbg_value(i32 %3, !20, !DIExpression(), !36)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !39
    #dbg_value(i32 %h, !19, !DIExpression(), !36)
  %m5 = call i32 @cqrt_measure_i32(i32 %h), !dbg !40
  %4 = add nsw i32 %3, %m5, !dbg !41
  ret i32 %4, !dbg !42
}

declare i32 @cqrt_qram_alloc_i32(i32)

declare i32 @cqrt_qram_load_i32(i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r4_qram_body_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e390512ea4e5633142d6cd62d0241c01")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !19, !20}
!15 = !DILocalVariable(name: "tbl", scope: !10, file: !8, line: 3, type: !16)
!16 = !DICompositeType(tag: DW_TAG_array_type, baseType: !13, size: 256, elements: !17)
!17 = !{!18}
!18 = !DISubrange(count: 8)
!19 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!20 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!21 = !DILocation(line: 3, column: 9, scope: !10)
!22 = !DILocation(line: 6, column: 10, scope: !10)
!23 = !DILocation(line: 4, column: 13, scope: !10)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 7, column: 10, scope: !10)
!26 = !DILocation(line: 7, column: 7, scope: !10)
!27 = !DILocation(line: 8, column: 9, scope: !10)
!28 = !DILocation(line: 9, column: 16, scope: !10)
!29 = !DILocation(line: 9, column: 14, scope: !10)
!30 = !DILocation(line: 9, column: 5, scope: !10)
!31 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !11, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!32 = !DILocation(line: 3, column: 9, scope: !10, inlinedAt: !33)
!33 = distinct !DILocation(line: 11, column: 25, scope: !31)
!34 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !33)
!35 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !33)
!36 = !DILocation(line: 0, scope: !10, inlinedAt: !33)
!37 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !33)
!38 = !DILocation(line: 7, column: 7, scope: !10, inlinedAt: !33)
!39 = !DILocation(line: 8, column: 9, scope: !10, inlinedAt: !33)
!40 = !DILocation(line: 9, column: 16, scope: !10, inlinedAt: !33)
!41 = !DILocation(line: 9, column: 14, scope: !10, inlinedAt: !33)
!42 = !DILocation(line: 11, column: 18, scope: !31)
