; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/fix_r1_probes/cust/vd_base.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/vd.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !15, !DIExpression(), !20)
    #dbg_value(i8 0, !16, !DIExpression(), !20)
    #dbg_value(i8 0, !18, !DIExpression(), !20)
    #dbg_value(i8 0, !19, !DIExpression(), !20)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !21
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !21
    #dbg_value(i32 %h, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
    #dbg_value(i32 %h, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
    #dbg_value(i32 %h, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !20)
  %bf = call i32 @cqrt_alloc_i1(i1 false), !dbg !24
  call void @cqrt_cnot(i32 %h, i32 %bf), !dbg !24
  %out = call i32 @cqrt_alloc_i32(i32 0), !dbg !24
  %selop = call i32 @cqrt_alloc_i32(i32 2), !dbg !24
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out), !dbg !24
  call void @cqrt_x(i32 %bf), !dbg !24
  %selop1 = call i32 @cqrt_alloc_i32(i32 5), !dbg !24
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out), !dbg !24
  call void @cqrt_x(i32 %bf), !dbg !24
  call void @cqrt_cnot(i32 %h, i32 %bf), !dbg !24
  call void @cqrt_free(i32 %bf), !dbg !24
    #dbg_value(i32 %out, !15, !DIExpression(), !20)
  %h6 = call i32 @cqrt_alloc_i1(i1 false), !dbg !25
  call void @cqrt_ry_i1(i32 %h6, double 5.000000e-01), !dbg !25
  call void @cqrt_ry_i1_controlled(i32 %h, i32 %h6, double -5.000000e-01), !dbg !28
    #dbg_value(i8 poison, !18, !DIExpression(), !20)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %out, i32 -3)
  %bf4 = call i32 @cqrt_alloc_i1(i1 false), !dbg !29
  call void @cqrt_cnot(i32 %h6, i32 %bf4), !dbg !29
  %out5 = call i32 @cqrt_alloc_i32(i32 0), !dbg !29
  call void @cqrt_copy_i32_controlled(i32 %bf4, i32 %h_op, i32 %out5), !dbg !29
  call void @cqrt_x(i32 %bf4), !dbg !29
  call void @cqrt_copy_i32_controlled(i32 %bf4, i32 %out, i32 %out5), !dbg !29
  call void @cqrt_x(i32 %bf4), !dbg !29
  call void @cqrt_cnot(i32 %h6, i32 %bf4), !dbg !29
  call void @cqrt_free(i32 %bf4), !dbg !29
    #dbg_value(i32 %out5, !15, !DIExpression(), !20)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %out5, i32 2), !dbg !30
  %h7 = call i32 @cqrt_alloc_i1(i1 false), !dbg !32
  call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h7, double 5.000000e-01), !dbg !32
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %out5, i32 2), !dbg !30
  call void @cqrt_free(i32 %h_cmp), !dbg !34
    #dbg_value(i8 poison, !19, !DIExpression(), !20)
  %h_op8 = call i32 @cq_template_add_i32_hl(i32 %out5, i32 -3)
  %bf2 = call i32 @cqrt_alloc_i1(i1 false), !dbg !35
  call void @cqrt_cnot(i32 %h7, i32 %bf2), !dbg !35
  %out3 = call i32 @cqrt_alloc_i32(i32 0), !dbg !35
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %h_op8, i32 %out3), !dbg !35
  call void @cqrt_x(i32 %bf2), !dbg !35
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %out5, i32 %out3), !dbg !35
  call void @cqrt_x(i32 %bf2), !dbg !35
  call void @cqrt_cnot(i32 %h7, i32 %bf2), !dbg !35
  call void @cqrt_free(i32 %bf2), !dbg !35
    #dbg_value(i32 %out3, !15, !DIExpression(), !20)
  %m = call i1 @cqrt_measure_i1(i32 %h), !dbg !36
  %1 = zext i1 %m to i32, !dbg !36
  %m9 = call i1 @cqrt_measure_i1(i32 %h6), !dbg !37
  %2 = zext i1 %m9 to i32, !dbg !37
  %3 = add nuw nsw i32 %2, %1, !dbg !38
  %m10 = call i1 @cqrt_measure_i1(i32 %h7), !dbg !39
  %4 = zext i1 %m10 to i32, !dbg !39
  %5 = add nuw nsw i32 %3, %4, !dbg !40
  %m11 = call i32 @cqrt_measure_i32(i32 %out3), !dbg !41
  %6 = add nsw i32 %5, %m11, !dbg !42
  ret i32 %6, !dbg !43
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)

declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

declare void @cqrt_ry_i1(i32, double)

declare void @cqrt_ry_i1_controlled(i32, i32, double)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i1 @cqrt_measure_i1(i32)

declare i32 @cqrt_measure_i32(i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/vd.c", directory: "/Users/sorenwilkening/Desktop/CQ_f2phi", checksumkind: CSK_MD5, checksum: "a30ea6d7fe196c04b3acc1e3f104d008")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18, !19}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 5, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "b1", scope: !10, file: !8, line: 6, type: !17)
!19 = !DILocalVariable(name: "b2", scope: !10, file: !8, line: 7, type: !17)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 10, column: 14, scope: !22)
!22 = distinct !DILexicalBlock(scope: !23, file: !8, line: 9, column: 16)
!23 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 9)
!24 = !DILocation(line: 12, column: 9, scope: !10)
!25 = !DILocation(line: 15, column: 14, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !8, line: 14, column: 16)
!27 = distinct !DILexicalBlock(scope: !10, file: !8, line: 14, column: 9)
!28 = !DILocation(line: 14, column: 9, scope: !10)
!29 = !DILocation(line: 17, column: 9, scope: !10)
!30 = !DILocation(line: 19, column: 11, scope: !31)
!31 = distinct !DILexicalBlock(scope: !10, file: !8, line: 19, column: 9)
!32 = !DILocation(line: 20, column: 14, scope: !33)
!33 = distinct !DILexicalBlock(scope: !31, file: !8, line: 19, column: 16)
!34 = !DILocation(line: 19, column: 9, scope: !10)
!35 = !DILocation(line: 22, column: 9, scope: !10)
!36 = !DILocation(line: 24, column: 12, scope: !10)
!37 = !DILocation(line: 24, column: 29, scope: !10)
!38 = !DILocation(line: 24, column: 27, scope: !10)
!39 = !DILocation(line: 24, column: 46, scope: !10)
!40 = !DILocation(line: 24, column: 44, scope: !10)
!41 = !DILocation(line: 24, column: 63, scope: !10)
!42 = !DILocation(line: 24, column: 61, scope: !10)
!43 = !DILocation(line: 24, column: 5, scope: !10)
