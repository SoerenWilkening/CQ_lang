; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.yKIQKRvX1L/s1.ll'
source_filename = "./w2e3_xor_on_rotated_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !21
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !21
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !23
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !23
    #dbg_value(i32 %h1, !19, !DIExpression(), !22)
    #dbg_value(i32 0, !20, !DIExpression(), !22)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 3.000000e-01), !dbg !24
    #dbg_value(i32 %h1, !19, !DIExpression(), !22)
  %h_op = call i32 @cq_template_xor_i32_hl(i32 %h1, i32 5), !dbg !27
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !27
    #dbg_value(i32 %m, !20, !DIExpression(), !22)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 3.000000e-01), !dbg !28
    #dbg_value(i32 %h1, !19, !DIExpression(), !22)
  %h_op2 = call i32 @cq_template_xor_i32_hl(i32 %h1, i32 5), !dbg !31
  %m3 = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !31
  %1 = add nsw i32 %m3, %m, !dbg !32
    #dbg_value(i32 %1, !20, !DIExpression(), !22)
  %m4 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !33
  %2 = add nsw i32 %1, %m4, !dbg !34
  %m5 = call i1 @cqrt_measure_i1(i32 %h), !dbg !35
  %3 = zext i1 %m5 to i32, !dbg !35
  %4 = add nsw i32 %2, %3, !dbg !36
  ret i32 %4, !dbg !37
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !38 {
  %1 = tail call i32 @slice(), !dbg !39
  ret i32 %1, !dbg !40
}

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cq_template_xor_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare i1 @cqrt_measure_i1(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!11}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "w2e3_xor_on_rotated_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "2cc37256a1eb309cc56b27cb46f10483")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2e3_xor_on_rotated_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "2cc37256a1eb309cc56b27cb46f10483")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 4, type: !10)
!19 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 5, type: !16)
!20 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 6, type: !16)
!21 = !DILocation(line: 4, column: 14, scope: !12)
!22 = !DILocation(line: 0, scope: !12)
!23 = !DILocation(line: 5, column: 14, scope: !12)
!24 = !DILocation(line: 8, column: 20, scope: !25)
!25 = distinct !DILexicalBlock(scope: !26, file: !13, line: 8, column: 13)
!26 = distinct !DILexicalBlock(scope: !12, file: !13, line: 7, column: 5)
!27 = !DILocation(line: 9, column: 14, scope: !26)
!28 = !DILocation(line: 12, column: 20, scope: !29)
!29 = distinct !DILexicalBlock(scope: !30, file: !13, line: 12, column: 13)
!30 = distinct !DILexicalBlock(scope: !12, file: !13, line: 11, column: 5)
!31 = !DILocation(line: 13, column: 14, scope: !30)
!32 = !DILocation(line: 13, column: 11, scope: !30)
!33 = !DILocation(line: 15, column: 16, scope: !12)
!34 = !DILocation(line: 15, column: 14, scope: !12)
!35 = !DILocation(line: 15, column: 32, scope: !12)
!36 = !DILocation(line: 15, column: 30, scope: !12)
!37 = !DILocation(line: 15, column: 5, scope: !12)
!38 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 17, type: !14, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!39 = !DILocation(line: 17, column: 25, scope: !38)
!40 = !DILocation(line: 17, column: 18, scope: !38)
