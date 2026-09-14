; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.l3ijjAD0mD/s1.ll'
source_filename = "./w2e7_stateprep_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !24
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !24
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !25)
    #dbg_value(i32 0, !19, !DIExpression(), !25)
    #dbg_value(i32 4, !20, !DIExpression(), !26)
  %h1 = call i32 @cqrt_alloc_i32(i32 4), !dbg !27
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 3.000000e-01), !dbg !27
    #dbg_value(i32 %h1, !20, !DIExpression(), !26)
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !29
    #dbg_value(i32 %m, !19, !DIExpression(), !25)
    #dbg_value(i32 4, !22, !DIExpression(), !30)
  %h2 = call i32 @cqrt_alloc_i32(i32 4), !dbg !31
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 3.000000e-01), !dbg !31
    #dbg_value(i32 %h2, !22, !DIExpression(), !30)
  %m3 = call i32 @cqrt_measure_i32(i32 %h2), !dbg !33
  %1 = add nsw i32 %m3, %m, !dbg !34
    #dbg_value(i32 %1, !19, !DIExpression(), !25)
  %m4 = call i1 @cqrt_measure_i1(i32 %h), !dbg !35
  %2 = zext i1 %m4 to i32, !dbg !35
  %3 = add nsw i32 %1, %2, !dbg !36
  ret i32 %3, !dbg !37
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !38 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !39
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !39
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !41)
    #dbg_value(i32 0, !19, !DIExpression(), !41)
    #dbg_value(i32 4, !20, !DIExpression(), !42)
  %h1 = call i32 @cqrt_alloc_i32(i32 4), !dbg !43
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 3.000000e-01), !dbg !43
    #dbg_value(i32 %h1, !20, !DIExpression(), !42)
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !44
    #dbg_value(i32 %m, !19, !DIExpression(), !41)
    #dbg_value(i32 4, !22, !DIExpression(), !45)
  %h2 = call i32 @cqrt_alloc_i32(i32 4), !dbg !46
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 3.000000e-01), !dbg !46
    #dbg_value(i32 %h2, !22, !DIExpression(), !45)
  %m3 = call i32 @cqrt_measure_i32(i32 %h2), !dbg !47
  %1 = add nsw i32 %m3, %m, !dbg !48
    #dbg_value(i32 %1, !19, !DIExpression(), !41)
  %m4 = call i1 @cqrt_measure_i1(i32 %h), !dbg !49
  %2 = zext i1 %m4 to i32, !dbg !49
  %3 = add nsw i32 %1, %2, !dbg !50
  ret i32 %3, !dbg !51
}

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cqrt_alloc_i32(i32)

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
!8 = !DIFile(filename: "w2e7_stateprep_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "a0041be3445168befad5b2c34647ecc0")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 4, type: !14, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2e7_stateprep_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "a0041be3445168befad5b2c34647ecc0")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !22}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 5, type: !10)
!19 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 6, type: !16)
!20 = !DILocalVariable(name: "r", scope: !21, file: !13, line: 8, type: !16)
!21 = distinct !DILexicalBlock(scope: !12, file: !13, line: 7, column: 5)
!22 = !DILocalVariable(name: "r", scope: !23, file: !13, line: 13, type: !16)
!23 = distinct !DILexicalBlock(scope: !12, file: !13, line: 12, column: 5)
!24 = !DILocation(line: 5, column: 14, scope: !12)
!25 = !DILocation(line: 0, scope: !12)
!26 = !DILocation(line: 0, scope: !21)
!27 = !DILocation(line: 9, column: 20, scope: !28)
!28 = distinct !DILexicalBlock(scope: !21, file: !13, line: 9, column: 13)
!29 = !DILocation(line: 10, column: 14, scope: !21)
!30 = !DILocation(line: 0, scope: !23)
!31 = !DILocation(line: 14, column: 20, scope: !32)
!32 = distinct !DILexicalBlock(scope: !23, file: !13, line: 14, column: 13)
!33 = !DILocation(line: 15, column: 14, scope: !23)
!34 = !DILocation(line: 15, column: 11, scope: !23)
!35 = !DILocation(line: 17, column: 16, scope: !12)
!36 = !DILocation(line: 17, column: 14, scope: !12)
!37 = !DILocation(line: 17, column: 5, scope: !12)
!38 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 19, type: !14, scopeLine: 19, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!39 = !DILocation(line: 5, column: 14, scope: !12, inlinedAt: !40)
!40 = distinct !DILocation(line: 19, column: 25, scope: !38)
!41 = !DILocation(line: 0, scope: !12, inlinedAt: !40)
!42 = !DILocation(line: 0, scope: !21, inlinedAt: !40)
!43 = !DILocation(line: 9, column: 20, scope: !28, inlinedAt: !40)
!44 = !DILocation(line: 10, column: 14, scope: !21, inlinedAt: !40)
!45 = !DILocation(line: 0, scope: !23, inlinedAt: !40)
!46 = !DILocation(line: 14, column: 20, scope: !32, inlinedAt: !40)
!47 = !DILocation(line: 15, column: 14, scope: !23, inlinedAt: !40)
!48 = !DILocation(line: 15, column: 11, scope: !23, inlinedAt: !40)
!49 = !DILocation(line: 17, column: 16, scope: !12, inlinedAt: !40)
!50 = !DILocation(line: 17, column: 14, scope: !12, inlinedAt: !40)
!51 = !DILocation(line: 19, column: 18, scope: !38)
