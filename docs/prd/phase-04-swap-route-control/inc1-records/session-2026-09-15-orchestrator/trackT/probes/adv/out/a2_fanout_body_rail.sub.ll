; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/a2_fanout_body_rail.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a2_fanout_body_rail.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !22
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !22
    #dbg_value(i32 %h, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 1, !17, !DIExpression(), !24)
  br label %3, !dbg !25

1:                                                ; preds = %3
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !26
    #dbg_value(i32 %h, !15, !DIExpression(), !23)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !27
  %2 = add nsw i32 %m, %7, !dbg !28
  ret i32 %2, !dbg !29

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 1, %0 ], [ %8, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %7, %3 ]
    #dbg_value(i32 %4, !17, !DIExpression(), !24)
    #dbg_value(i32 %5, !16, !DIExpression(), !23)
  %h_op = call i32 @cq_template_ashr_i32_hl(i32 %h, i32 %4), !dbg !30
    #dbg_value(i32 %h_op, !19, !DIExpression(), !31)
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !32
  %m3 = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !32
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 2), !dbg !33
  call void @cq_template_ashr_i32_hl_unc(i32 %h_op, i32 %h, i32 %4), !dbg !30
  call void @cqrt_free(i32 %h_op), !dbg !30
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !33
  %6 = add i32 %m3, %5, !dbg !34
  %7 = add i32 %6, %m4, !dbg !35
    #dbg_value(i32 %7, !16, !DIExpression(), !23)
  %8 = add nuw nsw i32 %4, 1, !dbg !36
    #dbg_value(i32 %8, !17, !DIExpression(), !24)
  %9 = icmp eq i32 %8, 3, !dbg !37
  br i1 %9, label %1, label %3, !dbg !25, !llvm.loop !38
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !42 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !43
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !43
    #dbg_value(i32 %h, !15, !DIExpression(), !45)
    #dbg_value(i32 0, !16, !DIExpression(), !45)
    #dbg_value(i32 1, !17, !DIExpression(), !46)
  br label %1, !dbg !47

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 1, %0 ], [ %6, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %5, %1 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !46)
    #dbg_value(i32 %3, !16, !DIExpression(), !45)
  %h_op = call i32 @cq_template_ashr_i32_hl(i32 %h, i32 %2), !dbg !48
    #dbg_value(i32 %h_op, !19, !DIExpression(), !49)
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !50
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !50
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 2), !dbg !51
  call void @cq_template_ashr_i32_hl_unc(i32 %h_op, i32 %h, i32 %2), !dbg !48
  call void @cqrt_free(i32 %h_op), !dbg !48
  %m3 = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !51
  %4 = add i32 %m, %3, !dbg !52
  %5 = add i32 %4, %m3, !dbg !53
    #dbg_value(i32 %5, !16, !DIExpression(), !45)
  %6 = add nuw nsw i32 %2, 1, !dbg !54
    #dbg_value(i32 %6, !17, !DIExpression(), !46)
  %7 = icmp eq i32 %6, 3, !dbg !55
  br i1 %7, label %8, label %1, !dbg !47, !llvm.loop !56

8:                                                ; preds = %1
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !58
    #dbg_value(i32 %h, !15, !DIExpression(), !45)
  %m4 = call i32 @cqrt_measure_i32(i32 %h), !dbg !59
  %9 = add nsw i32 %m4, %5, !dbg !60
  ret i32 %9, !dbg !61
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_ashr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_ashr_i32_hl_unc(i32, i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a2_fanout_body_rail.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "278cd02483560693c354553fba660cdf")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 8, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!19 = !DILocalVariable(name: "t", scope: !20, file: !8, line: 9, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 8, column: 34)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!22 = !DILocation(line: 6, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 8, column: 5, scope: !18)
!26 = !DILocation(line: 12, column: 9, scope: !10)
!27 = !DILocation(line: 13, column: 16, scope: !10)
!28 = !DILocation(line: 13, column: 14, scope: !10)
!29 = !DILocation(line: 13, column: 5, scope: !10)
!30 = !DILocation(line: 9, column: 19, scope: !20)
!31 = !DILocation(line: 0, scope: !20)
!32 = !DILocation(line: 10, column: 14, scope: !20)
!33 = !DILocation(line: 10, column: 34, scope: !20)
!34 = !DILocation(line: 10, column: 32, scope: !20)
!35 = !DILocation(line: 10, column: 11, scope: !20)
!36 = !DILocation(line: 8, column: 29, scope: !21)
!37 = !DILocation(line: 8, column: 23, scope: !21)
!38 = distinct !{!38, !25, !39, !40, !41}
!39 = !DILocation(line: 11, column: 5, scope: !18)
!40 = !{!"llvm.loop.mustprogress"}
!41 = !{!"llvm.loop.unroll.disable"}
!42 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!43 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !44)
!44 = distinct !DILocation(line: 15, column: 25, scope: !42)
!45 = !DILocation(line: 0, scope: !10, inlinedAt: !44)
!46 = !DILocation(line: 0, scope: !18, inlinedAt: !44)
!47 = !DILocation(line: 8, column: 5, scope: !18, inlinedAt: !44)
!48 = !DILocation(line: 9, column: 19, scope: !20, inlinedAt: !44)
!49 = !DILocation(line: 0, scope: !20, inlinedAt: !44)
!50 = !DILocation(line: 10, column: 14, scope: !20, inlinedAt: !44)
!51 = !DILocation(line: 10, column: 34, scope: !20, inlinedAt: !44)
!52 = !DILocation(line: 10, column: 32, scope: !20, inlinedAt: !44)
!53 = !DILocation(line: 10, column: 11, scope: !20, inlinedAt: !44)
!54 = !DILocation(line: 8, column: 29, scope: !21, inlinedAt: !44)
!55 = !DILocation(line: 8, column: 23, scope: !21, inlinedAt: !44)
!56 = distinct !{!56, !47, !57, !40, !41}
!57 = !DILocation(line: 11, column: 5, scope: !18, inlinedAt: !44)
!58 = !DILocation(line: 12, column: 9, scope: !10, inlinedAt: !44)
!59 = !DILocation(line: 13, column: 16, scope: !10, inlinedAt: !44)
!60 = !DILocation(line: 13, column: 14, scope: !10, inlinedAt: !44)
!61 = !DILocation(line: 15, column: 18, scope: !42)
