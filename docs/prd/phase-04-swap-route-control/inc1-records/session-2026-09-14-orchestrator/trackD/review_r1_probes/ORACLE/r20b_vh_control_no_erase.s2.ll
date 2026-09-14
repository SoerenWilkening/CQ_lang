; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes/s1/r20b_vh_control_no_erase.ll'
source_filename = "src/r20b_vh_control_no_erase.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !12 {
    #dbg_value(i32 %0, !17, !DIExpression(), !22)
  %h1 = call i32 @cqrt_alloc_i32(i32 %0), !dbg !23
  call void @cqrt_ry_i32(i32 %h1, double 5.000000e-01), !dbg !23
    #dbg_value(i32 %h1, !18, !DIExpression(), !22)
  call void @cqrt_ry_i32(i32 %h1, double 3.000000e-01), !dbg !24
    #dbg_value(i32 %h1, !19, !DIExpression(), !22)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !25
  call void @cqrt_ry_i1(i32 %h, double 2.500000e-01), !dbg !25
    #dbg_value(i32 %h, !20, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i32 %h1, !21, !DIExpression(), !22)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 0x3FE6666666666666), !dbg !26
    #dbg_value(i32 %h1, !21, !DIExpression(), !22)
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !29
  ret i32 %m, !dbg !30
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !31 {
    #dbg_value(i32 3, !17, !DIExpression(), !34)
  %h1 = call i32 @cqrt_alloc_i32(i32 3), !dbg !36
  call void @cqrt_ry_i32(i32 %h1, double 5.000000e-01), !dbg !36
    #dbg_value(i32 %h1, !18, !DIExpression(), !34)
  call void @cqrt_ry_i32(i32 %h1, double 3.000000e-01), !dbg !37
    #dbg_value(i32 %h1, !19, !DIExpression(), !34)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !38
  call void @cqrt_ry_i1(i32 %h, double 2.500000e-01), !dbg !38
    #dbg_value(i32 %h, !20, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !34)
    #dbg_value(i32 %h1, !21, !DIExpression(), !34)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 0x3FE6666666666666), !dbg !39
    #dbg_value(i32 %h1, !21, !DIExpression(), !34)
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !40
  ret i32 %m, !dbg !41
}

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cqrt_measure_i32(i32)

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
!8 = !DIFile(filename: "src/r20b_vh_control_no_erase.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes", checksumkind: CSK_MD5, checksum: "a86e60c0c6b187facff3ffe0796e7cb9")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 4, type: !13, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15, !15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19, !20, !21}
!17 = !DILocalVariable(name: "u", arg: 1, scope: !12, file: !8, line: 4, type: !15)
!18 = !DILocalVariable(name: "q", scope: !12, file: !8, line: 4, type: !15)
!19 = !DILocalVariable(name: "a", scope: !12, file: !8, line: 4, type: !15)
!20 = !DILocalVariable(name: "f", scope: !12, file: !8, line: 5, type: !10)
!21 = !DILocalVariable(name: "r", scope: !12, file: !8, line: 5, type: !15)
!22 = !DILocation(line: 0, scope: !12)
!23 = !DILocation(line: 4, column: 25, scope: !12)
!24 = !DILocation(line: 4, column: 48, scope: !12)
!25 = !DILocation(line: 5, column: 10, scope: !12)
!26 = !DILocation(line: 6, column: 12, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !8, line: 6, column: 8)
!28 = distinct !DILexicalBlock(scope: !12, file: !8, line: 6, column: 6)
!29 = !DILocation(line: 7, column: 10, scope: !12)
!30 = !DILocation(line: 7, column: 3, scope: !12)
!31 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 8, type: !32, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!32 = !DISubroutineType(types: !33)
!33 = !{!15}
!34 = !DILocation(line: 0, scope: !12, inlinedAt: !35)
!35 = distinct !DILocation(line: 8, column: 24, scope: !31)
!36 = !DILocation(line: 4, column: 25, scope: !12, inlinedAt: !35)
!37 = !DILocation(line: 4, column: 48, scope: !12, inlinedAt: !35)
!38 = !DILocation(line: 5, column: 10, scope: !12, inlinedAt: !35)
!39 = !DILocation(line: 6, column: 12, scope: !27, inlinedAt: !35)
!40 = !DILocation(line: 7, column: 10, scope: !12, inlinedAt: !35)
!41 = !DILocation(line: 8, column: 17, scope: !31)
