; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.yfFOJfPxt8/s1.ll'
source_filename = "./w2b_sameloop_mixed.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !27
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !27
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !28)
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !29
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01), !dbg !29
    #dbg_value(i32 %h2, !19, !DIExpression(), !28)
    #dbg_value(i32 0, !20, !DIExpression(), !28)
    #dbg_value(i32 0, !21, !DIExpression(), !30)
  br label %2, !dbg !31

1:                                                ; preds = %2
  ret i32 %8, !dbg !32

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %9, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %8, %2 ]
    #dbg_value(i32 %h2, !19, !DIExpression(), !28)
    #dbg_value(i32 %3, !21, !DIExpression(), !30)
    #dbg_value(i32 %4, !20, !DIExpression(), !28)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 3.000000e-01), !dbg !33
    #dbg_value(i32 %h2, !19, !DIExpression(), !28)
  %h1 = call i32 @cqrt_alloc_i1(i1 false), !dbg !35
  call void @cqrt_ry_i1(i32 %h1, double 4.000000e-01), !dbg !35
    #dbg_value(i32 %h1, !23, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !36)
  %h3 = call i32 @cqrt_alloc_i32(i32 3), !dbg !37
  call void @cqrt_ry_i32(i32 %h3, double 1.500000e-01), !dbg !37
    #dbg_value(i32 %h3, !26, !DIExpression(), !36)
  call void @cqrt_ry_i32_controlled(i32 %h1, i32 %h3, double 2.000000e-01), !dbg !38
    #dbg_value(i32 %h3, !26, !DIExpression(), !36)
  %m = call i32 @cqrt_measure_i32(i32 %h2), !dbg !40
  %m4 = call i32 @cqrt_measure_i32(i32 %h3), !dbg !41
  %m5 = call i1 @cqrt_measure_i1(i32 %h1), !dbg !42
  %5 = zext i1 %m5 to i32, !dbg !42
  %6 = add i32 %m, %4, !dbg !43
  %7 = add i32 %6, %m4, !dbg !44
  %8 = add i32 %7, %5, !dbg !45
    #dbg_value(i32 %8, !20, !DIExpression(), !28)
  %9 = add nuw nsw i32 %3, 1, !dbg !46
    #dbg_value(i32 %h2, !19, !DIExpression(), !28)
    #dbg_value(i32 %9, !21, !DIExpression(), !30)
  %10 = icmp eq i32 %3, 0, !dbg !47
  br i1 %10, label %2, label %1, !dbg !31, !llvm.loop !48
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !52 {
  %1 = tail call i32 @slice(), !dbg !53
  ret i32 %1, !dbg !54
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
!8 = !DIFile(filename: "w2b_sameloop_mixed.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "175e8e0885a16abdd38a2b84785df2e6")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 8, type: !14, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2b_sameloop_mixed.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "175e8e0885a16abdd38a2b84785df2e6")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21, !23, !26}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 9, type: !10)
!19 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 10, type: !16)
!20 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 11, type: !16)
!21 = !DILocalVariable(name: "k", scope: !22, file: !13, line: 12, type: !16)
!22 = distinct !DILexicalBlock(scope: !12, file: !13, line: 12, column: 5)
!23 = !DILocalVariable(name: "t", scope: !24, file: !13, line: 14, type: !10)
!24 = distinct !DILexicalBlock(scope: !25, file: !13, line: 12, column: 33)
!25 = distinct !DILexicalBlock(scope: !22, file: !13, line: 12, column: 5)
!26 = !DILocalVariable(name: "w", scope: !24, file: !13, line: 15, type: !16)
!27 = !DILocation(line: 9, column: 14, scope: !12)
!28 = !DILocation(line: 0, scope: !12)
!29 = !DILocation(line: 10, column: 14, scope: !12)
!30 = !DILocation(line: 0, scope: !22)
!31 = !DILocation(line: 12, column: 5, scope: !22)
!32 = !DILocation(line: 19, column: 5, scope: !12)
!33 = !DILocation(line: 13, column: 20, scope: !34)
!34 = distinct !DILexicalBlock(scope: !24, file: !13, line: 13, column: 13)
!35 = !DILocation(line: 14, column: 18, scope: !24)
!36 = !DILocation(line: 0, scope: !24)
!37 = !DILocation(line: 15, column: 18, scope: !24)
!38 = !DILocation(line: 16, column: 20, scope: !39)
!39 = distinct !DILexicalBlock(scope: !24, file: !13, line: 16, column: 13)
!40 = !DILocation(line: 17, column: 14, scope: !24)
!41 = !DILocation(line: 17, column: 30, scope: !24)
!42 = !DILocation(line: 17, column: 46, scope: !24)
!43 = !DILocation(line: 17, column: 28, scope: !24)
!44 = !DILocation(line: 17, column: 44, scope: !24)
!45 = !DILocation(line: 17, column: 11, scope: !24)
!46 = !DILocation(line: 12, column: 28, scope: !25)
!47 = !DILocation(line: 12, column: 23, scope: !25)
!48 = distinct !{!48, !31, !49, !50, !51}
!49 = !DILocation(line: 18, column: 5, scope: !22)
!50 = !{!"llvm.loop.mustprogress"}
!51 = !{!"llvm.loop.unroll.disable"}
!52 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 21, type: !14, scopeLine: 21, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!53 = !DILocation(line: 21, column: 25, scope: !52)
!54 = !DILocation(line: 21, column: 18, scope: !52)
