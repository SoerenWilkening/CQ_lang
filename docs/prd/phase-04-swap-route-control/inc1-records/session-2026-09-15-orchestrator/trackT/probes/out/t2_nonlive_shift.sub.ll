; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/out/t2_nonlive_shift.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t2_nonlive_shift.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !19
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !19
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 1, !17, !DIExpression(), !21)
  br label %3, !dbg !22

1:                                                ; preds = %3
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !23
  %2 = add nsw i32 %m, %6, !dbg !24
  ret i32 %2, !dbg !25

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 1, %0 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %6, %3 ]
    #dbg_value(i32 %4, !17, !DIExpression(), !21)
    #dbg_value(i32 %5, !16, !DIExpression(), !20)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %4), !dbg !26
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !26
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %4), !dbg !26
  call void @cqrt_free(i32 %h_op), !dbg !26
  %m2 = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !26
  %6 = add nsw i32 %m2, %5, !dbg !28
    #dbg_value(i32 %6, !16, !DIExpression(), !20)
  %7 = add nuw nsw i32 %4, 1, !dbg !29
    #dbg_value(i32 %7, !17, !DIExpression(), !21)
  %8 = icmp eq i32 %7, 3, !dbg !30
  br i1 %8, label %1, label %3, !dbg !22, !llvm.loop !31
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !35 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !36
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !36
    #dbg_value(i32 %h, !15, !DIExpression(), !38)
    #dbg_value(i32 0, !16, !DIExpression(), !38)
    #dbg_value(i32 1, !17, !DIExpression(), !39)
  br label %1, !dbg !40

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 1, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !39)
    #dbg_value(i32 %3, !16, !DIExpression(), !38)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %2), !dbg !41
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !41
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %2), !dbg !41
  call void @cqrt_free(i32 %h_op), !dbg !41
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !41
  %4 = add nsw i32 %m, %3, !dbg !42
    #dbg_value(i32 %4, !16, !DIExpression(), !38)
  %5 = add nuw nsw i32 %2, 1, !dbg !43
    #dbg_value(i32 %5, !17, !DIExpression(), !39)
  %6 = icmp eq i32 %5, 3, !dbg !44
  br i1 %6, label %7, label %1, !dbg !40, !llvm.loop !45

7:                                                ; preds = %1
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !47
  %8 = add nsw i32 %m2, %4, !dbg !48
  ret i32 %8, !dbg !49
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/t2_nonlive_shift.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "62b54c2045e5eb67419694803af2155d")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 9, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!19 = !DILocation(line: 7, column: 13, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 9, column: 5, scope: !18)
!23 = !DILocation(line: 11, column: 16, scope: !10)
!24 = !DILocation(line: 11, column: 14, scope: !10)
!25 = !DILocation(line: 11, column: 5, scope: !10)
!26 = !DILocation(line: 10, column: 14, scope: !27)
!27 = distinct !DILexicalBlock(scope: !18, file: !8, line: 9, column: 5)
!28 = !DILocation(line: 10, column: 11, scope: !27)
!29 = !DILocation(line: 9, column: 29, scope: !27)
!30 = !DILocation(line: 9, column: 23, scope: !27)
!31 = distinct !{!31, !22, !32, !33, !34}
!32 = !DILocation(line: 10, column: 14, scope: !18)
!33 = !{!"llvm.loop.mustprogress"}
!34 = !{!"llvm.loop.unroll.disable"}
!35 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!36 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !37)
!37 = distinct !DILocation(line: 13, column: 25, scope: !35)
!38 = !DILocation(line: 0, scope: !10, inlinedAt: !37)
!39 = !DILocation(line: 0, scope: !18, inlinedAt: !37)
!40 = !DILocation(line: 9, column: 5, scope: !18, inlinedAt: !37)
!41 = !DILocation(line: 10, column: 14, scope: !27, inlinedAt: !37)
!42 = !DILocation(line: 10, column: 11, scope: !27, inlinedAt: !37)
!43 = !DILocation(line: 9, column: 29, scope: !27, inlinedAt: !37)
!44 = !DILocation(line: 9, column: 23, scope: !27, inlinedAt: !37)
!45 = distinct !{!45, !40, !46, !33, !34}
!46 = !DILocation(line: 10, column: 14, scope: !18, inlinedAt: !37)
!47 = !DILocation(line: 11, column: 16, scope: !10, inlinedAt: !37)
!48 = !DILocation(line: 11, column: 14, scope: !10, inlinedAt: !37)
!49 = !DILocation(line: 13, column: 18, scope: !35)
