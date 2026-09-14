; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p4_sideways_guard.stage1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p4_sideways_guard.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !16, !DIExpression(), !22)
    #dbg_value(i8 0, !17, !DIExpression(), !22)
    #dbg_value(i8 0, !19, !DIExpression(), !22)
    #dbg_value(i8 0, !20, !DIExpression(), !22)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !23
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !23
    #dbg_value(i32 %h, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i32 %h, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i32 %h, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i32 poison, !16, !DIExpression(), !22)
    #dbg_value(i32 poison, !21, !DIExpression(), !22)
  %h4 = call i32 @cqrt_alloc_i1(i1 false), !dbg !26
  call void @cqrt_ry_i1(i32 %h4, double 5.000000e-01), !dbg !26
  call void @cqrt_ry_i1_controlled(i32 %h, i32 %h4, double -5.000000e-01), !dbg !29
    #dbg_value(i8 poison, !19, !DIExpression(), !22)
    #dbg_value(i32 poison, !16, !DIExpression(), !22)
  %h5 = call i32 @cqrt_alloc_i1(i1 false), !dbg !30
  call void @cqrt_ry_i1(i32 %h5, double 5.000000e-01), !dbg !30
  call void @cqrt_ry_i1_controlled(i32 %h, i32 %h5, double -5.000000e-01), !dbg !33
    #dbg_value(i32 %out, !16, !DIExpression(), !22)
    #dbg_value(i32 %out, !21, !DIExpression(), !22)
  %bf = call i32 @cqrt_alloc_i1(i1 false), !dbg !22
  call void @cqrt_cnot(i32 %h, i32 %bf), !dbg !22
  %out = call i32 @cqrt_alloc_i32(i32 0), !dbg !22
  %selop = call i32 @cqrt_alloc_i32(i32 2), !dbg !22
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out), !dbg !22
  call void @cqrt_x(i32 %bf), !dbg !22
  %selop1 = call i32 @cqrt_alloc_i32(i32 5), !dbg !22
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out), !dbg !22
  call void @cqrt_x(i32 %bf), !dbg !22
  call void @cqrt_cnot(i32 %h, i32 %bf), !dbg !22
  call void @cqrt_free(i32 %bf), !dbg !22
  %h_op = call i32 @cq_template_add_i32_hl(i32 %out, i32 -3)
  %bf2 = call i32 @cqrt_alloc_i1(i1 false), !dbg !34
  call void @cqrt_cnot(i32 %h4, i32 %bf2), !dbg !34
  %out3 = call i32 @cqrt_alloc_i32(i32 0), !dbg !34
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %h_op, i32 %out3), !dbg !34
  call void @cqrt_x(i32 %bf2), !dbg !34
  call void @cqrt_copy_i32_controlled(i32 %bf2, i32 %out, i32 %out3), !dbg !34
  call void @cqrt_x(i32 %bf2), !dbg !34
  call void @cqrt_cnot(i32 %h4, i32 %bf2), !dbg !34
  call void @cqrt_free(i32 %bf2), !dbg !34
    #dbg_value(i32 %out3, !16, !DIExpression(), !22)
    #dbg_value(i8 poison, !20, !DIExpression(), !22)
  %m = call i1 @cqrt_measure_i1(i32 %h), !dbg !35
  %1 = zext i1 %m to i32, !dbg !35
  %m6 = call i1 @cqrt_measure_i1(i32 %h4), !dbg !36
  %2 = zext i1 %m6 to i32, !dbg !36
  %3 = add nuw nsw i32 %2, %1, !dbg !37
  %m7 = call i1 @cqrt_measure_i1(i32 %h5), !dbg !38
  %4 = zext i1 %m7 to i32, !dbg !38
  %5 = add nuw nsw i32 %3, %4, !dbg !39
  %m8 = call i32 @cqrt_measure_i32(i32 %out3), !dbg !40
  %6 = add nsw i32 %5, %m8, !dbg !41
  ret i32 %6, !dbg !42
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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p4_sideways_guard.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "f7c3c6a47bbc481a2996861ef27a19f5")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 6, type: !12, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p4_sideways_guard.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "f7c3c6a47bbc481a2996861ef27a19f5")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !19, !20, !21}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 7, type: !14)
!17 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 8, type: !18)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 8, type: !18)
!20 = !DILocalVariable(name: "b2", scope: !10, file: !11, line: 8, type: !18)
!21 = !DILocalVariable(name: "pre", scope: !10, file: !11, line: 11, type: !14)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 9, column: 24, scope: !24)
!24 = distinct !DILexicalBlock(scope: !25, file: !11, line: 9, column: 17)
!25 = distinct !DILexicalBlock(scope: !10, file: !11, line: 9, column: 9)
!26 = !DILocation(line: 12, column: 24, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !11, line: 12, column: 17)
!28 = distinct !DILexicalBlock(scope: !10, file: !11, line: 12, column: 9)
!29 = !DILocation(line: 12, column: 9, scope: !10)
!30 = !DILocation(line: 14, column: 26, scope: !31)
!31 = distinct !DILexicalBlock(scope: !32, file: !11, line: 14, column: 19)
!32 = distinct !DILexicalBlock(scope: !10, file: !11, line: 14, column: 9)
!33 = !DILocation(line: 14, column: 9, scope: !10)
!34 = !DILocation(line: 13, column: 9, scope: !10)
!35 = !DILocation(line: 15, column: 12, scope: !10)
!36 = !DILocation(line: 15, column: 27, scope: !10)
!37 = !DILocation(line: 15, column: 26, scope: !10)
!38 = !DILocation(line: 15, column: 42, scope: !10)
!39 = !DILocation(line: 15, column: 41, scope: !10)
!40 = !DILocation(line: 15, column: 57, scope: !10)
!41 = !DILocation(line: 15, column: 56, scope: !10)
!42 = !DILocation(line: 15, column: 5, scope: !10)
