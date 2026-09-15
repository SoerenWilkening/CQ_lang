; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/r1_break_loop.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r1_break_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !19
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !19
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 1, !17, !DIExpression(), !21)
  br label %1, !dbg !22

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 1, %0 ], [ %6, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !21)
    #dbg_value(i32 %3, !16, !DIExpression(), !20)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %2), !dbg !23
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !23
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %2), !dbg !23
  call void @cqrt_free(i32 %h_op), !dbg !23
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !23
  %4 = add nsw i32 %m, %3, !dbg !26
    #dbg_value(i32 %4, !16, !DIExpression(), !20)
  %5 = icmp sgt i32 %4, 1, !dbg !27
    #dbg_value(i32 %2, !17, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !21)
  %6 = add nuw nsw i32 %2, 1
    #dbg_value(i32 %6, !17, !DIExpression(), !21)
    #dbg_value(i32 %6, !17, !DIExpression(), !21)
    #dbg_value(i32 %4, !16, !DIExpression(), !20)
  %7 = icmp eq i32 %6, 5
  %8 = select i1 %5, i1 true, i1 %7, !dbg !29
  br i1 %8, label %9, label %1, !dbg !29, !llvm.loop !30

9:                                                ; preds = %1
    #dbg_value(i32 %4, !16, !DIExpression(), !20)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !34
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !35
  %10 = add nsw i32 %m2, %4, !dbg !36
  ret i32 %10, !dbg !37
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !38 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !39
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !39
    #dbg_value(i32 %h, !15, !DIExpression(), !41)
    #dbg_value(i32 0, !16, !DIExpression(), !41)
    #dbg_value(i32 1, !17, !DIExpression(), !42)
  br label %1, !dbg !43

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 1, %0 ], [ %6, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !42)
    #dbg_value(i32 %3, !16, !DIExpression(), !41)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %2), !dbg !44
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !44
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %2), !dbg !44
  call void @cqrt_free(i32 %h_op), !dbg !44
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !44
  %4 = add nsw i32 %m, %3, !dbg !45
    #dbg_value(i32 %4, !16, !DIExpression(), !41)
  %5 = icmp sgt i32 %4, 1, !dbg !46
    #dbg_value(i32 %2, !17, !DIExpression(DW_OP_plus_uconst, 1, DW_OP_stack_value), !42)
  %6 = add nuw nsw i32 %2, 1
    #dbg_value(i32 %6, !17, !DIExpression(), !42)
    #dbg_value(i32 %6, !17, !DIExpression(), !42)
    #dbg_value(i32 %4, !16, !DIExpression(), !41)
  %7 = icmp eq i32 %6, 5
  %8 = select i1 %5, i1 true, i1 %7, !dbg !47
  br i1 %8, label %9, label %1, !dbg !47, !llvm.loop !48

9:                                                ; preds = %1
    #dbg_value(i32 %4, !16, !DIExpression(), !41)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !50
    #dbg_value(i32 %h, !15, !DIExpression(), !41)
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !51
  %10 = add nsw i32 %m2, %4, !dbg !52
  ret i32 %10, !dbg !53
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r1_break_loop.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "b9060f20c4039ae54c1c27f7090e5d0c")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 8, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!19 = !DILocation(line: 6, column: 13, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 8, column: 5, scope: !18)
!23 = !DILocation(line: 9, column: 14, scope: !24)
!24 = distinct !DILexicalBlock(scope: !25, file: !8, line: 8, column: 34)
!25 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!26 = !DILocation(line: 9, column: 11, scope: !24)
!27 = !DILocation(line: 10, column: 15, scope: !28)
!28 = distinct !DILexicalBlock(scope: !24, file: !8, line: 10, column: 13)
!29 = !DILocation(line: 10, column: 13, scope: !24)
!30 = distinct !{!30, !22, !31, !32, !33}
!31 = !DILocation(line: 11, column: 5, scope: !18)
!32 = !{!"llvm.loop.mustprogress"}
!33 = !{!"llvm.loop.unroll.disable"}
!34 = !DILocation(line: 12, column: 9, scope: !10)
!35 = !DILocation(line: 13, column: 16, scope: !10)
!36 = !DILocation(line: 13, column: 14, scope: !10)
!37 = !DILocation(line: 13, column: 5, scope: !10)
!38 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!39 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !40)
!40 = distinct !DILocation(line: 15, column: 25, scope: !38)
!41 = !DILocation(line: 0, scope: !10, inlinedAt: !40)
!42 = !DILocation(line: 0, scope: !18, inlinedAt: !40)
!43 = !DILocation(line: 8, column: 5, scope: !18, inlinedAt: !40)
!44 = !DILocation(line: 9, column: 14, scope: !24, inlinedAt: !40)
!45 = !DILocation(line: 9, column: 11, scope: !24, inlinedAt: !40)
!46 = !DILocation(line: 10, column: 15, scope: !28, inlinedAt: !40)
!47 = !DILocation(line: 10, column: 13, scope: !24, inlinedAt: !40)
!48 = distinct !{!48, !43, !49, !32, !33}
!49 = !DILocation(line: 11, column: 5, scope: !18, inlinedAt: !40)
!50 = !DILocation(line: 12, column: 9, scope: !10, inlinedAt: !40)
!51 = !DILocation(line: 13, column: 16, scope: !10, inlinedAt: !40)
!52 = !DILocation(line: 13, column: 14, scope: !10, inlinedAt: !40)
!53 = !DILocation(line: 15, column: 18, scope: !38)
