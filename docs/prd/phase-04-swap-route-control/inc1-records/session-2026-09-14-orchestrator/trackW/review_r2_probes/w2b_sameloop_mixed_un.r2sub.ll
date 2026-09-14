; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.Q6vZu4my7l/s1.ll'
source_filename = "./w2b_sameloop_mixed_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !27
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !27
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !28)
  %h3 = call i32 @cqrt_alloc_i32(i32 7), !dbg !29
  call void @cqrt_ry_i32(i32 %h3, double 2.500000e-01), !dbg !29
    #dbg_value(i32 %h3, !19, !DIExpression(), !28)
    #dbg_value(i32 0, !20, !DIExpression(), !28)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h3, double 3.000000e-01), !dbg !30
    #dbg_value(i32 %h3, !19, !DIExpression(), !28)
  %h1 = call i32 @cqrt_alloc_i1(i1 false), !dbg !32
  call void @cqrt_ry_i1(i32 %h1, double 4.000000e-01), !dbg !32
    #dbg_value(i32 %h1, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !33)
  %h4 = call i32 @cqrt_alloc_i32(i32 3), !dbg !34
  call void @cqrt_ry_i32(i32 %h4, double 1.500000e-01), !dbg !34
    #dbg_value(i32 %h4, !23, !DIExpression(), !33)
  call void @cqrt_ry_i32_controlled(i32 %h1, i32 %h4, double 2.000000e-01), !dbg !35
    #dbg_value(i32 %h4, !23, !DIExpression(), !33)
  %m = call i32 @cqrt_measure_i32(i32 %h3), !dbg !37
  %m6 = call i32 @cqrt_measure_i32(i32 %h4), !dbg !38
  %m7 = call i1 @cqrt_measure_i1(i32 %h1), !dbg !39
    #dbg_value(!DIArgList(i32 %m, i1 %m7, i32 %m6), !20, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 2, DW_OP_plus, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_plus, DW_OP_stack_value), !28)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h3, double 3.000000e-01), !dbg !40
    #dbg_value(i32 %h3, !19, !DIExpression(), !28)
  %h2 = call i32 @cqrt_alloc_i1(i1 false), !dbg !42
  call void @cqrt_ry_i1(i32 %h2, double 4.000000e-01), !dbg !42
    #dbg_value(i32 %h2, !24, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !43)
  %h5 = call i32 @cqrt_alloc_i32(i32 3), !dbg !44
  call void @cqrt_ry_i32(i32 %h5, double 1.500000e-01), !dbg !44
    #dbg_value(i32 %h5, !26, !DIExpression(), !43)
  call void @cqrt_ry_i32_controlled(i32 %h2, i32 %h5, double 2.000000e-01), !dbg !45
    #dbg_value(!DIArgList(i32 poison, i1 poison), !20, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_plus, DW_OP_stack_value), !28)
  %1 = zext i1 %m7 to i32, !dbg !39
    #dbg_value(!DIArgList(i32 poison, i32 poison), !20, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !28)
    #dbg_value(i32 poison, !20, !DIExpression(), !28)
    #dbg_value(i32 %h5, !26, !DIExpression(), !43)
  %m8 = call i32 @cqrt_measure_i32(i32 %h3), !dbg !47
  %m9 = call i32 @cqrt_measure_i32(i32 %h5), !dbg !48
  %m10 = call i1 @cqrt_measure_i1(i32 %h2), !dbg !49
  %2 = zext i1 %m10 to i32, !dbg !49
  %3 = add i32 %m6, %m, !dbg !50
  %4 = add i32 %3, %1, !dbg !51
  %5 = add i32 %4, %m8, !dbg !52
  %6 = add i32 %5, %m9, !dbg !53
  %7 = add i32 %6, %2, !dbg !54
    #dbg_value(i32 %7, !20, !DIExpression(), !28)
  ret i32 %7, !dbg !55
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !56 {
  %1 = tail call i32 @slice(), !dbg !57
  ret i32 %1, !dbg !58
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
!8 = !DIFile(filename: "w2b_sameloop_mixed_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "aea9b2742810fdd611c7ddedbdc9b7cd")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2b_sameloop_mixed_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "aea9b2742810fdd611c7ddedbdc9b7cd")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21, !23, !24, !26}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 4, type: !10)
!19 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 5, type: !16)
!20 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 6, type: !16)
!21 = !DILocalVariable(name: "t", scope: !22, file: !13, line: 8, type: !10)
!22 = distinct !DILexicalBlock(scope: !12, file: !13, line: 7, column: 5)
!23 = !DILocalVariable(name: "w", scope: !22, file: !13, line: 8, type: !16)
!24 = !DILocalVariable(name: "t", scope: !25, file: !13, line: 12, type: !10)
!25 = distinct !DILexicalBlock(scope: !12, file: !13, line: 11, column: 5)
!26 = !DILocalVariable(name: "w", scope: !25, file: !13, line: 12, type: !16)
!27 = !DILocation(line: 4, column: 14, scope: !12)
!28 = !DILocation(line: 0, scope: !12)
!29 = !DILocation(line: 5, column: 14, scope: !12)
!30 = !DILocation(line: 7, column: 18, scope: !31)
!31 = distinct !DILexicalBlock(scope: !22, file: !13, line: 7, column: 11)
!32 = !DILocation(line: 8, column: 16, scope: !22)
!33 = !DILocation(line: 0, scope: !22)
!34 = !DILocation(line: 8, column: 48, scope: !22)
!35 = !DILocation(line: 9, column: 18, scope: !36)
!36 = distinct !DILexicalBlock(scope: !22, file: !13, line: 9, column: 11)
!37 = !DILocation(line: 10, column: 12, scope: !22)
!38 = !DILocation(line: 10, column: 28, scope: !22)
!39 = !DILocation(line: 10, column: 44, scope: !22)
!40 = !DILocation(line: 11, column: 18, scope: !41)
!41 = distinct !DILexicalBlock(scope: !25, file: !13, line: 11, column: 11)
!42 = !DILocation(line: 12, column: 16, scope: !25)
!43 = !DILocation(line: 0, scope: !25)
!44 = !DILocation(line: 12, column: 48, scope: !25)
!45 = !DILocation(line: 13, column: 18, scope: !46)
!46 = distinct !DILexicalBlock(scope: !25, file: !13, line: 13, column: 11)
!47 = !DILocation(line: 14, column: 12, scope: !25)
!48 = !DILocation(line: 14, column: 28, scope: !25)
!49 = !DILocation(line: 14, column: 44, scope: !25)
!50 = !DILocation(line: 14, column: 26, scope: !25)
!51 = !DILocation(line: 14, column: 42, scope: !25)
!52 = !DILocation(line: 10, column: 26, scope: !22)
!53 = !DILocation(line: 10, column: 42, scope: !22)
!54 = !DILocation(line: 14, column: 9, scope: !25)
!55 = !DILocation(line: 15, column: 5, scope: !12)
!56 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 17, type: !14, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!57 = !DILocation(line: 17, column: 25, scope: !56)
!58 = !DILocation(line: 17, column: 18, scope: !56)
