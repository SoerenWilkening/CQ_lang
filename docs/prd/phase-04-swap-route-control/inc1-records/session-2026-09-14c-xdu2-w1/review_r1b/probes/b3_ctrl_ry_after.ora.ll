; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b3_ctrl_ry_after.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b3_ctrl_ry_after.c"
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
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h1, i32 0), !dbg !25
  call void @cqrt_x(i32 %h_cmp), !dbg !27
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h, double 9.000000e-01), !dbg !28
  call void @cqrt_x(i32 %h_cmp), !dbg !27
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h1, i32 0), !dbg !25
  call void @cqrt_free(i32 %h_cmp), !dbg !27
    #dbg_value(i32 %h, !15, !DIExpression(), !21)
  %m3 = call i32 @cqrt_measure_i32(i32 %h), !dbg !29
  %2 = add nsw i32 %m3, %7, !dbg !30
  %m4 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !31
  %3 = add nsw i32 %2, %m4, !dbg !32
  ret i32 %3, !dbg !33

4:                                                ; preds = %4, %0
  %5 = phi i32 [ 1, %0 ], [ %8, %4 ]
  %6 = phi i32 [ 0, %0 ], [ %7, %4 ]
    #dbg_value(i32 %5, !18, !DIExpression(), !23)
    #dbg_value(i32 %6, !17, !DIExpression(), !21)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %5), !dbg !34
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !34
  %m = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !34
  %7 = add nsw i32 %m, %6, !dbg !36
    #dbg_value(i32 %7, !17, !DIExpression(), !21)
  %8 = add nuw nsw i32 %5, 1, !dbg !37
    #dbg_value(i32 %8, !18, !DIExpression(), !23)
  %9 = icmp eq i32 %8, 3, !dbg !38
  br i1 %9, label %1, label %4, !dbg !24, !llvm.loop !39
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !43 {
  %1 = tail call i32 @slice(), !dbg !44
  ret i32 %1, !dbg !45
}

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b3_ctrl_ry_after.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "55c30448bc480d3d1f787e2edb9c4945")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 9, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 10, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 5)
!20 = !DILocation(line: 7, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 8, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !19)
!24 = !DILocation(line: 10, column: 5, scope: !19)
!25 = !DILocation(line: 12, column: 9, scope: !26)
!26 = distinct !DILexicalBlock(scope: !10, file: !8, line: 12, column: 9)
!27 = !DILocation(line: 12, column: 9, scope: !10)
!28 = !DILocation(line: 12, column: 16, scope: !26)
!29 = !DILocation(line: 13, column: 16, scope: !10)
!30 = !DILocation(line: 13, column: 14, scope: !10)
!31 = !DILocation(line: 13, column: 32, scope: !10)
!32 = !DILocation(line: 13, column: 30, scope: !10)
!33 = !DILocation(line: 13, column: 5, scope: !10)
!34 = !DILocation(line: 11, column: 14, scope: !35)
!35 = distinct !DILexicalBlock(scope: !19, file: !8, line: 10, column: 5)
!36 = !DILocation(line: 11, column: 11, scope: !35)
!37 = !DILocation(line: 10, column: 29, scope: !35)
!38 = !DILocation(line: 10, column: 23, scope: !35)
!39 = distinct !{!39, !24, !40, !41, !42}
!40 = !DILocation(line: 11, column: 14, scope: !19)
!41 = !{!"llvm.loop.mustprogress"}
!42 = !{!"llvm.loop.unroll.disable"}
!43 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!44 = !DILocation(line: 15, column: 25, scope: !43)
!45 = !DILocation(line: 15, column: 18, scope: !43)
