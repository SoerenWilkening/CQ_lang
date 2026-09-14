; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.yiPGUVirDT/s1.ll'
source_filename = "./w2e4_two_rail_regions_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483646, -2147483648) i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !22
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !22
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !23)
  %h1 = call i32 @cqrt_alloc_i1(i1 false), !dbg !24
  call void @cqrt_ry_i1(i32 %h1, double 6.000000e-01), !dbg !24
    #dbg_value(i32 %h1, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !23)
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !25
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01), !dbg !25
    #dbg_value(i32 %h2, !20, !DIExpression(), !23)
    #dbg_value(i32 0, !21, !DIExpression(), !23)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 3.000000e-01), !dbg !26
    #dbg_value(i32 %h2, !20, !DIExpression(), !23)
  call void @cqrt_ry_i32_controlled(i32 %h1, i32 %h2, double 4.000000e-01), !dbg !29
    #dbg_value(i32 %h2, !20, !DIExpression(), !23)
    #dbg_value(i32 1, !21, !DIExpression(), !23)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 3.000000e-01), !dbg !31
    #dbg_value(i32 %h2, !20, !DIExpression(), !23)
  call void @cqrt_ry_i32_controlled(i32 %h1, i32 %h2, double 4.000000e-01), !dbg !34
    #dbg_value(i32 %h2, !20, !DIExpression(), !23)
    #dbg_value(i32 2, !21, !DIExpression(), !23)
  %m = call i32 @cqrt_measure_i32(i32 %h2), !dbg !36
  %1 = add nsw i32 %m, 2, !dbg !37
  %m3 = call i1 @cqrt_measure_i1(i32 %h), !dbg !38
  %2 = zext i1 %m3 to i32, !dbg !38
  %3 = add nsw i32 %1, %2, !dbg !39
  %m4 = call i1 @cqrt_measure_i1(i32 %h1), !dbg !40
  %4 = zext i1 %m4 to i32, !dbg !40
  %5 = add nsw i32 %3, %4, !dbg !41
  ret i32 %5, !dbg !42
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483646, -2147483648) i32 @main() local_unnamed_addr #0 !dbg !43 {
  %1 = tail call i32 @slice(), !dbg !44
  ret i32 %1, !dbg !45
}

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

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
!8 = !DIFile(filename: "w2e4_two_rail_regions_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "499d8bba05e549f830527ba9e170ad86")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2e4_two_rail_regions_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "499d8bba05e549f830527ba9e170ad86")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21}
!18 = !DILocalVariable(name: "b0", scope: !12, file: !13, line: 4, type: !10)
!19 = !DILocalVariable(name: "b1", scope: !12, file: !13, line: 5, type: !10)
!20 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 6, type: !16)
!21 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 7, type: !16)
!22 = !DILocation(line: 4, column: 15, scope: !12)
!23 = !DILocation(line: 0, scope: !12)
!24 = !DILocation(line: 5, column: 15, scope: !12)
!25 = !DILocation(line: 6, column: 14, scope: !12)
!26 = !DILocation(line: 9, column: 21, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !13, line: 9, column: 13)
!28 = distinct !DILexicalBlock(scope: !12, file: !13, line: 8, column: 5)
!29 = !DILocation(line: 10, column: 21, scope: !30)
!30 = distinct !DILexicalBlock(scope: !28, file: !13, line: 10, column: 13)
!31 = !DILocation(line: 14, column: 21, scope: !32)
!32 = distinct !DILexicalBlock(scope: !33, file: !13, line: 14, column: 13)
!33 = distinct !DILexicalBlock(scope: !12, file: !13, line: 13, column: 5)
!34 = !DILocation(line: 15, column: 21, scope: !35)
!35 = distinct !DILexicalBlock(scope: !33, file: !13, line: 15, column: 13)
!36 = !DILocation(line: 18, column: 16, scope: !12)
!37 = !DILocation(line: 18, column: 14, scope: !12)
!38 = !DILocation(line: 18, column: 32, scope: !12)
!39 = !DILocation(line: 18, column: 30, scope: !12)
!40 = !DILocation(line: 18, column: 49, scope: !12)
!41 = !DILocation(line: 18, column: 47, scope: !12)
!42 = !DILocation(line: 18, column: 5, scope: !12)
!43 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 20, type: !14, scopeLine: 20, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!44 = !DILocation(line: 20, column: 25, scope: !43)
!45 = !DILocation(line: 20, column: 18, scope: !43)
