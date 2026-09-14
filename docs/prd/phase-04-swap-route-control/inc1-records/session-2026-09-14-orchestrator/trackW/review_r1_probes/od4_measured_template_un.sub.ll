; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.QTpYBVtDY8/s1.ll'
source_filename = "./od4_measured_template_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
    #dbg_value(i32 0, !18, !DIExpression(), !25)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !26
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !26
    #dbg_value(i32 %h, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !27)
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !28
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01), !dbg !28
    #dbg_value(i32 %h2, !21, !DIExpression(), !27)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 2.000000e-01), !dbg !29
    #dbg_value(i32 %h2, !21, !DIExpression(), !27)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h2, i32 3), !dbg !31
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !31
  %m5 = call i1 @cqrt_measure_i1(i32 %h), !dbg !32
    #dbg_value(!DIArgList(i32 %m, i1 %m5), !18, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_plus, DW_OP_stack_value), !25)
  %h1 = call i32 @cqrt_alloc_i1(i1 false), !dbg !33
  call void @cqrt_ry_i1(i32 %h1, double 5.000000e-01), !dbg !33
    #dbg_value(i32 %h1, !22, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !34)
  %h3 = call i32 @cqrt_alloc_i32(i32 7), !dbg !35
  call void @cqrt_ry_i32(i32 %h3, double 2.500000e-01), !dbg !35
    #dbg_value(i32 %h3, !24, !DIExpression(), !34)
  call void @cqrt_ry_i32_controlled(i32 %h1, i32 %h3, double 2.000000e-01), !dbg !36
  %1 = zext i1 %m5 to i32, !dbg !32
    #dbg_value(!DIArgList(i32 %m, i32 %1), !18, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !25)
    #dbg_value(i32 poison, !18, !DIExpression(), !25)
    #dbg_value(i32 %h3, !24, !DIExpression(), !34)
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h3, i32 3), !dbg !38
  %m6 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !38
  %m7 = call i1 @cqrt_measure_i1(i32 %h1), !dbg !39
  %2 = zext i1 %m7 to i32, !dbg !39
  %3 = add i32 %m, %1, !dbg !40
  %4 = add i32 %3, %m6, !dbg !41
  %5 = add i32 %4, %2, !dbg !42
    #dbg_value(i32 %5, !18, !DIExpression(), !25)
  ret i32 %5, !dbg !43
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !44 {
  %1 = tail call i32 @slice(), !dbg !45
  ret i32 %1, !dbg !46
}

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

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
!8 = !DIFile(filename: "od4_measured_template_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "bbd9eca504dc3b03206757967d717bc4")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 2, type: !14, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./od4_measured_template_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "bbd9eca504dc3b03206757967d717bc4")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !21, !22, !24}
!18 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 3, type: !16)
!19 = !DILocalVariable(name: "t", scope: !20, file: !13, line: 4, type: !10)
!20 = distinct !DILexicalBlock(scope: !12, file: !13, line: 4, column: 5)
!21 = !DILocalVariable(name: "r", scope: !20, file: !13, line: 4, type: !16)
!22 = !DILocalVariable(name: "t", scope: !23, file: !13, line: 5, type: !10)
!23 = distinct !DILexicalBlock(scope: !12, file: !13, line: 5, column: 5)
!24 = !DILocalVariable(name: "r", scope: !23, file: !13, line: 5, type: !16)
!25 = !DILocation(line: 0, scope: !12)
!26 = !DILocation(line: 4, column: 16, scope: !20)
!27 = !DILocation(line: 0, scope: !20)
!28 = !DILocation(line: 4, column: 48, scope: !20)
!29 = !DILocation(line: 4, column: 78, scope: !30)
!30 = distinct !DILexicalBlock(scope: !20, file: !13, line: 4, column: 71)
!31 = !DILocation(line: 4, column: 101, scope: !20)
!32 = !DILocation(line: 4, column: 121, scope: !20)
!33 = !DILocation(line: 5, column: 16, scope: !23)
!34 = !DILocation(line: 0, scope: !23)
!35 = !DILocation(line: 5, column: 48, scope: !23)
!36 = !DILocation(line: 5, column: 78, scope: !37)
!37 = distinct !DILexicalBlock(scope: !23, file: !13, line: 5, column: 71)
!38 = !DILocation(line: 5, column: 101, scope: !23)
!39 = !DILocation(line: 5, column: 121, scope: !23)
!40 = !DILocation(line: 5, column: 119, scope: !23)
!41 = !DILocation(line: 4, column: 119, scope: !20)
!42 = !DILocation(line: 5, column: 98, scope: !23)
!43 = !DILocation(line: 6, column: 5, scope: !12)
!44 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 8, type: !14, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!45 = !DILocation(line: 8, column: 25, scope: !44)
!46 = !DILocation(line: 8, column: 18, scope: !44)
