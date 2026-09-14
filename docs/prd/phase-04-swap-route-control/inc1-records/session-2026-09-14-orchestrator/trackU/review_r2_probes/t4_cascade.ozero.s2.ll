; ModuleID = 't4_cascade.ozero.s1.ll'
source_filename = "t4_cascade.zero.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !15, !DIExpression(), !19)
    #dbg_value(i8 0, !16, !DIExpression(), !19)
    #dbg_value(i8 0, !18, !DIExpression(), !19)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !20
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !20
    #dbg_value(i32 %h, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !19)
    #dbg_value(i32 %h, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !19)
    #dbg_value(i32 %h, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !19)
    #dbg_value(i32 poison, !15, !DIExpression(), !19)
  %h4 = call i32 @cqrt_alloc_i1(i1 false), !dbg !23
  call void @cqrt_ry_i1(i32 %h4, double 5.000000e-01), !dbg !23
  call void @cqrt_ry_i1_controlled(i32 %h, i32 %h4, double -5.000000e-01), !dbg !26
    #dbg_value(i32 %out, !15, !DIExpression(), !19)
    #dbg_value(i8 poison, !18, !DIExpression(), !19)
  %bf = call i32 @cqrt_alloc_i1(i1 false), !dbg !19
  call void @cqrt_cnot(i32 %h, i32 %bf), !dbg !19
  %out = call i32 @cqrt_alloc_i32(i32 0), !dbg !19
  %selop = call i32 @cqrt_alloc_i32(i32 2), !dbg !19
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out), !dbg !19
  call void @cqrt_x(i32 %bf), !dbg !19
  %selop1 = call i32 @cqrt_alloc_i32(i32 5), !dbg !19
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out), !dbg !19
  call void @cqrt_x(i32 %bf), !dbg !19
  call void @cqrt_cnot(i32 %h, i32 %bf), !dbg !19
  call void @cqrt_free(i32 %bf), !dbg !19
  %h_op = call i32 @cq_template_add_i32_hl(i32 %out, i32 -3)
  %bf2 = call i32 @cqrt_alloc_i1(i1 false), !dbg !27
  call void @cqrt_cnot(i32 %h4, i32 %bf2), !dbg !27
  %out3 = call i32 @cqrt_alloc_i32(i32 0), !dbg !27
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %h_op, i32 %out3), !dbg !27
  call void @cqrt_x(i32 %bf2), !dbg !27
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %out, i32 %out3), !dbg !27
  call void @cqrt_x(i32 %bf2), !dbg !27
  call void @cqrt_cnot(i32 %h4, i32 %bf2), !dbg !27
  call void @cqrt_free(i32 %bf2), !dbg !27
    #dbg_value(i32 %out3, !15, !DIExpression(), !19)
  %m = call i1 @cqrt_measure_i1(i32 %h), !dbg !28
  %1 = zext i1 %m to i32, !dbg !28
  %m5 = call i1 @cqrt_measure_i1(i32 %h4), !dbg !29
  %2 = zext i1 %m5 to i32, !dbg !29
  %3 = add nuw nsw i32 %2, %1, !dbg !30
  %m6 = call i32 @cqrt_measure_i32(i32 %out3), !dbg !31
  %4 = add nsw i32 %3, %m6, !dbg !32
  ret i32 %4, !dbg !33
}

declare void @cqrt_x(i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_free(i32)

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
!8 = !DIFile(filename: "t4_cascade.zero.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r2_probes", checksumkind: CSK_MD5, checksum: "0d2144df4e9be15feca28ad276a8db3b")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 3, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "b1", scope: !10, file: !8, line: 3, type: !17)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 4, column: 24, scope: !21)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 4, column: 17)
!22 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 9)
!23 = !DILocation(line: 6, column: 24, scope: !24)
!24 = distinct !DILexicalBlock(scope: !25, file: !8, line: 6, column: 17)
!25 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 9)
!26 = !DILocation(line: 6, column: 9, scope: !10)
!27 = !DILocation(line: 7, column: 9, scope: !10)
!28 = !DILocation(line: 8, column: 12, scope: !10)
!29 = !DILocation(line: 8, column: 29, scope: !10)
!30 = !DILocation(line: 8, column: 27, scope: !10)
!31 = !DILocation(line: 8, column: 46, scope: !10)
!32 = !DILocation(line: 8, column: 44, scope: !10)
!33 = !DILocation(line: 8, column: 5, scope: !10)
