; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.9VsfLjn7OH/s1.ll'
source_filename = "./d4_noRailRegion.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !13 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !26
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !26
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !27)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !28
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !28
    #dbg_value(i32 %h1, !19, !DIExpression(), !27)
    #dbg_value(i32 0, !20, !DIExpression(), !27)
    #dbg_value(i32 0, !21, !DIExpression(), !29)
  %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h)
  br label %3, !dbg !30

1:                                                ; preds = %3
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !31
  %2 = add nsw i32 %m, %6, !dbg !32
  ret i32 %2, !dbg !33

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %6, %3 ]
    #dbg_value(i32 %h1, !19, !DIExpression(), !27)
    #dbg_value(i32 %4, !21, !DIExpression(), !29)
    #dbg_value(i32 %5, !20, !DIExpression(), !27)
  %h2 = call i32 @cqrt_alloc_i32(i32 5), !dbg !34
  call void @cqrt_ry_i32(i32 %h2, double 5.000000e-01), !dbg !34
    #dbg_value(i32 %h2, !23, !DIExpression(), !35)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h2, i32 2), !dbg !36
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !36
  call void @cqrt_x(i32 %h_cmp), !dbg !38
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 2.000000e-01), !dbg !39
  call void @cqrt_x(i32 %h_cmp), !dbg !38
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 0), !dbg !36
  call void @cqrt_free(i32 %h_cmp), !dbg !38
    #dbg_value(i32 %h1, !19, !DIExpression(), !27)
  %h_op3 = call i32 @cq_template_add_i32(i32 %h2, i32 %h_cast), !dbg !40
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !40
  %6 = add nsw i32 %m4, %5, !dbg !41
    #dbg_value(i32 %6, !20, !DIExpression(), !27)
  %7 = add nuw nsw i32 %4, 1, !dbg !42
    #dbg_value(i32 %7, !21, !DIExpression(), !29)
  %8 = icmp eq i32 %4, 0, !dbg !43
  br i1 %8, label %3, label %1, !dbg !30, !llvm.loop !44
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !48 {
  %1 = tail call i32 @slice(), !dbg !49
  ret i32 %1, !dbg !50
}

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cq_template_zext_i1_to_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_add_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!12}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "d4_noRailRegion.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "e04d77cb450d654d7ce72d4ca8d81765")
!9 = !{!10, !11}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!12 = !{!"Homebrew clang version 19.1.7"}
!13 = distinct !DISubprogram(name: "slice", scope: !14, file: !14, line: 8, type: !15, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!14 = !DIFile(filename: "./d4_noRailRegion.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "e04d77cb450d654d7ce72d4ca8d81765")
!15 = !DISubroutineType(types: !16)
!16 = !{!11}
!17 = !{!18, !19, !20, !21, !23}
!18 = !DILocalVariable(name: "b", scope: !13, file: !14, line: 9, type: !10)
!19 = !DILocalVariable(name: "r", scope: !13, file: !14, line: 10, type: !11)
!20 = !DILocalVariable(name: "s", scope: !13, file: !14, line: 11, type: !11)
!21 = !DILocalVariable(name: "k", scope: !22, file: !14, line: 12, type: !11)
!22 = distinct !DILexicalBlock(scope: !13, file: !14, line: 12, column: 5)
!23 = !DILocalVariable(name: "u", scope: !24, file: !14, line: 13, type: !11)
!24 = distinct !DILexicalBlock(scope: !25, file: !14, line: 12, column: 36)
!25 = distinct !DILexicalBlock(scope: !22, file: !14, line: 12, column: 5)
!26 = !DILocation(line: 9, column: 14, scope: !13)
!27 = !DILocation(line: 0, scope: !13)
!28 = !DILocation(line: 10, column: 13, scope: !13)
!29 = !DILocation(line: 0, scope: !22)
!30 = !DILocation(line: 12, column: 5, scope: !22)
!31 = !DILocation(line: 17, column: 16, scope: !13)
!32 = !DILocation(line: 17, column: 14, scope: !13)
!33 = !DILocation(line: 17, column: 5, scope: !13)
!34 = !DILocation(line: 13, column: 17, scope: !24)
!35 = !DILocation(line: 0, scope: !24)
!36 = !DILocation(line: 14, column: 22, scope: !37)
!37 = distinct !DILexicalBlock(scope: !24, file: !14, line: 14, column: 13)
!38 = !DILocation(line: 14, column: 13, scope: !24)
!39 = !DILocation(line: 14, column: 31, scope: !37)
!40 = !DILocation(line: 15, column: 14, scope: !24)
!41 = !DILocation(line: 15, column: 11, scope: !24)
!42 = !DILocation(line: 12, column: 31, scope: !25)
!43 = !DILocation(line: 12, column: 23, scope: !25)
!44 = distinct !{!44, !30, !45, !46, !47}
!45 = !DILocation(line: 16, column: 5, scope: !22)
!46 = !{!"llvm.loop.mustprogress"}
!47 = !{!"llvm.loop.unroll.disable"}
!48 = distinct !DISubprogram(name: "main", scope: !14, file: !14, line: 19, type: !15, scopeLine: 19, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!49 = !DILocation(line: 19, column: 25, scope: !48)
!50 = !DILocation(line: 19, column: 18, scope: !48)
