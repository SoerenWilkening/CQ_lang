; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b8_angle_select_after.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b8_angle_select_after.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !20
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !20
    #dbg_value(i32 %h, !15, !DIExpression(), !21)
  %h1 = call i32 @cqrt_alloc_i32(i32 0), !dbg !22
  call void @cqrt_ry_i32(i32 %h1, double 3.000000e-01), !dbg !22
    #dbg_value(i32 %h1, !16, !DIExpression(), !21)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
    #dbg_value(i32 1, !18, !DIExpression(), !23)
  br label %4, !dbg !24

1:                                                ; preds = %4
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !25
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h1, i32 0), !dbg !25
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h, double 0xBFE6666666666666), !dbg !25
    #dbg_value(i32 %h, !15, !DIExpression(), !21)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h1, i32 0), !dbg !25
  call void @cqrt_free(i32 %h_cmp), !dbg !25
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !26
  %2 = add nsw i32 %m, %7, !dbg !27
  %m3 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !28
  %3 = add nsw i32 %2, %m3, !dbg !29
  ret i32 %3, !dbg !30

4:                                                ; preds = %4, %0
  %5 = phi i32 [ 1, %0 ], [ %8, %4 ]
  %6 = phi i32 [ 0, %0 ], [ %7, %4 ]
    #dbg_value(i32 %5, !18, !DIExpression(), !23)
    #dbg_value(i32 %6, !17, !DIExpression(), !21)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %5), !dbg !31
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !31
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !31
  %7 = add nsw i32 %m4, %6, !dbg !33
    #dbg_value(i32 %7, !17, !DIExpression(), !21)
  %8 = add nuw nsw i32 %5, 1, !dbg !34
    #dbg_value(i32 %8, !18, !DIExpression(), !23)
  %9 = icmp eq i32 %8, 3, !dbg !35
  br i1 %9, label %1, label %4, !dbg !24, !llvm.loop !36
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !40 {
  %1 = tail call i32 @slice(), !dbg !41
  ret i32 %1, !dbg !42
}

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b8_angle_select_after.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "cf65fd792ac68f8ec4655e21fba26677")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 5, type: !13)
!16 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 6, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 8, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!20 = !DILocation(line: 5, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 6, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !19)
!24 = !DILocation(line: 8, column: 5, scope: !19)
!25 = !DILocation(line: 10, column: 9, scope: !10)
!26 = !DILocation(line: 11, column: 16, scope: !10)
!27 = !DILocation(line: 11, column: 14, scope: !10)
!28 = !DILocation(line: 11, column: 32, scope: !10)
!29 = !DILocation(line: 11, column: 30, scope: !10)
!30 = !DILocation(line: 11, column: 5, scope: !10)
!31 = !DILocation(line: 9, column: 14, scope: !32)
!32 = distinct !DILexicalBlock(scope: !19, file: !8, line: 8, column: 5)
!33 = !DILocation(line: 9, column: 11, scope: !32)
!34 = !DILocation(line: 8, column: 29, scope: !32)
!35 = !DILocation(line: 8, column: 23, scope: !32)
!36 = distinct !{!36, !24, !37, !38, !39}
!37 = !DILocation(line: 9, column: 14, scope: !19)
!38 = !{!"llvm.loop.mustprogress"}
!39 = !{!"llvm.loop.unroll.disable"}
!40 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!41 = !DILocation(line: 13, column: 25, scope: !40)
!42 = !DILocation(line: 13, column: 18, scope: !40)
