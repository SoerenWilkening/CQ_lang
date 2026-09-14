; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.1C83WlLEGf/s1.ll'
source_filename = "./a1_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !23
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01), !dbg !23
    #dbg_value(i32 %h2, !18, !DIExpression(), !24)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !25
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !25
    #dbg_value(i32 %h, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !26)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 2.000000e-01), !dbg !27
    #dbg_value(i32 %h2, !18, !DIExpression(), !24)
  %h1 = call i32 @cqrt_alloc_i1(i1 false), !dbg !29
  call void @cqrt_ry_i1(i32 %h1, double 5.000000e-01), !dbg !29
    #dbg_value(i32 %h1, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !30)
  call void @cqrt_ry_i32_controlled(i32 %h1, i32 %h2, double 2.000000e-01), !dbg !31
    #dbg_value(i32 %h2, !18, !DIExpression(), !24)
  %m = call i32 @cqrt_measure_i32(i32 %h2), !dbg !33
  ret i32 %m, !dbg !34
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !35 {
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !36
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01), !dbg !36
    #dbg_value(i32 %h2, !18, !DIExpression(), !38)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !39
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !39
    #dbg_value(i32 %h, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !40)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 2.000000e-01), !dbg !41
    #dbg_value(i32 %h2, !18, !DIExpression(), !38)
  %h1 = call i32 @cqrt_alloc_i1(i1 false), !dbg !42
  call void @cqrt_ry_i1(i32 %h1, double 5.000000e-01), !dbg !42
    #dbg_value(i32 %h1, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !43)
  call void @cqrt_ry_i32_controlled(i32 %h1, i32 %h2, double 2.000000e-01), !dbg !44
    #dbg_value(i32 %h2, !18, !DIExpression(), !38)
  %m = call i32 @cqrt_measure_i32(i32 %h2), !dbg !45
  ret i32 %m, !dbg !46
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
!8 = !DIFile(filename: "a1_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "020199197f8c282b182f0f27e6edca55")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 2, type: !14, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./a1_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "020199197f8c282b182f0f27e6edca55")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !21}
!18 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 3, type: !16)
!19 = !DILocalVariable(name: "b", scope: !20, file: !13, line: 4, type: !10)
!20 = distinct !DILexicalBlock(scope: !12, file: !13, line: 4, column: 5)
!21 = !DILocalVariable(name: "b", scope: !22, file: !13, line: 5, type: !10)
!22 = distinct !DILexicalBlock(scope: !12, file: !13, line: 5, column: 5)
!23 = !DILocation(line: 3, column: 13, scope: !12)
!24 = !DILocation(line: 0, scope: !12)
!25 = !DILocation(line: 4, column: 16, scope: !20)
!26 = !DILocation(line: 0, scope: !20)
!27 = !DILocation(line: 4, column: 51, scope: !28)
!28 = distinct !DILexicalBlock(scope: !20, file: !13, line: 4, column: 44)
!29 = !DILocation(line: 5, column: 16, scope: !22)
!30 = !DILocation(line: 0, scope: !22)
!31 = !DILocation(line: 5, column: 51, scope: !32)
!32 = distinct !DILexicalBlock(scope: !22, file: !13, line: 5, column: 44)
!33 = !DILocation(line: 6, column: 12, scope: !12)
!34 = !DILocation(line: 6, column: 5, scope: !12)
!35 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 8, type: !14, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!36 = !DILocation(line: 3, column: 13, scope: !12, inlinedAt: !37)
!37 = distinct !DILocation(line: 8, column: 25, scope: !35)
!38 = !DILocation(line: 0, scope: !12, inlinedAt: !37)
!39 = !DILocation(line: 4, column: 16, scope: !20, inlinedAt: !37)
!40 = !DILocation(line: 0, scope: !20, inlinedAt: !37)
!41 = !DILocation(line: 4, column: 51, scope: !28, inlinedAt: !37)
!42 = !DILocation(line: 5, column: 16, scope: !22, inlinedAt: !37)
!43 = !DILocation(line: 0, scope: !22, inlinedAt: !37)
!44 = !DILocation(line: 5, column: 51, scope: !32, inlinedAt: !37)
!45 = !DILocation(line: 6, column: 12, scope: !12, inlinedAt: !37)
!46 = !DILocation(line: 8, column: 18, scope: !35)
