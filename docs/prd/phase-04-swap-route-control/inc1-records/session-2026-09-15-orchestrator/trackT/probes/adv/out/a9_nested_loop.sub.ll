; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/a9_nested_loop.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a9_nested_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !22
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !22
    #dbg_value(i32 %h, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 1, !17, !DIExpression(), !24)
  br label %1, !dbg !25

1:                                                ; preds = %6, %0
  %2 = phi i32 [ 1, %0 ], [ %7, %6 ]
  %3 = phi i32 [ 0, %0 ], [ %13, %6 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !24)
    #dbg_value(i32 %3, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !19, !DIExpression(), !26)
    #dbg_value(i32 %3, !16, !DIExpression(), !23)
  br label %9, !dbg !27

4:                                                ; preds = %6
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !28
    #dbg_value(i32 %h, !15, !DIExpression(), !23)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !29
  %5 = add nsw i32 %m, %13, !dbg !30
  ret i32 %5, !dbg !31

6:                                                ; preds = %9
  %7 = add nuw nsw i32 %2, 1, !dbg !32
    #dbg_value(i32 %7, !17, !DIExpression(), !24)
    #dbg_value(i32 %13, !16, !DIExpression(), !23)
  %8 = icmp eq i32 %7, 3, !dbg !33
  br i1 %8, label %4, label %1, !dbg !25, !llvm.loop !34

9:                                                ; preds = %9, %1
  %10 = phi i32 [ 0, %1 ], [ %14, %9 ]
  %11 = phi i32 [ %3, %1 ], [ %13, %9 ]
    #dbg_value(i32 %10, !19, !DIExpression(), !26)
    #dbg_value(i32 %11, !16, !DIExpression(), !23)
  %12 = add nuw nsw i32 %10, %2, !dbg !38
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %12), !dbg !38
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !38
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %12), !dbg !38
  call void @cqrt_free(i32 %h_op), !dbg !38
  %m2 = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !38
  %13 = add nsw i32 %m2, %11, !dbg !40
    #dbg_value(i32 %13, !16, !DIExpression(), !23)
  %14 = add nuw nsw i32 %10, 1, !dbg !41
    #dbg_value(i32 %14, !19, !DIExpression(), !26)
  %15 = icmp eq i32 %10, 0, !dbg !42
  br i1 %15, label %9, label %6, !dbg !27, !llvm.loop !43
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !45 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !46
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !46
    #dbg_value(i32 %h, !15, !DIExpression(), !48)
    #dbg_value(i32 0, !16, !DIExpression(), !48)
    #dbg_value(i32 1, !17, !DIExpression(), !49)
  br label %1, !dbg !50

1:                                                ; preds = %4, %0
  %2 = phi i32 [ 1, %0 ], [ %5, %4 ]
  %3 = phi i32 [ 0, %0 ], [ %11, %4 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !49)
    #dbg_value(i32 %3, !16, !DIExpression(), !48)
    #dbg_value(i32 0, !19, !DIExpression(), !51)
    #dbg_value(i32 %3, !16, !DIExpression(), !48)
  br label %7, !dbg !52

4:                                                ; preds = %7
  %5 = add nuw nsw i32 %2, 1, !dbg !53
    #dbg_value(i32 %5, !17, !DIExpression(), !49)
    #dbg_value(i32 %11, !16, !DIExpression(), !48)
  %6 = icmp eq i32 %5, 3, !dbg !54
  br i1 %6, label %14, label %1, !dbg !50, !llvm.loop !55

7:                                                ; preds = %7, %1
  %8 = phi i32 [ 0, %1 ], [ %12, %7 ]
  %9 = phi i32 [ %3, %1 ], [ %11, %7 ]
    #dbg_value(i32 %8, !19, !DIExpression(), !51)
    #dbg_value(i32 %9, !16, !DIExpression(), !48)
  %10 = add nuw nsw i32 %8, %2, !dbg !57
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %10), !dbg !57
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !57
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %10), !dbg !57
  call void @cqrt_free(i32 %h_op), !dbg !57
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !57
  %11 = add nsw i32 %m, %9, !dbg !58
    #dbg_value(i32 %11, !16, !DIExpression(), !48)
  %12 = add nuw nsw i32 %8, 1, !dbg !59
    #dbg_value(i32 %12, !19, !DIExpression(), !51)
  %13 = icmp eq i32 %8, 0, !dbg !60
  br i1 %13, label %7, label %4, !dbg !52, !llvm.loop !61

14:                                               ; preds = %4
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !63
    #dbg_value(i32 %h, !15, !DIExpression(), !48)
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !64
  %15 = add nsw i32 %m2, %11, !dbg !65
  ret i32 %15, !dbg !66
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a9_nested_loop.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "bc2733bb572ff19a55579408637c1274")
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
!19 = !DILocalVariable(name: "j", scope: !20, file: !8, line: 9, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 9, column: 9)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!22 = !DILocation(line: 6, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 8, column: 5, scope: !18)
!26 = !DILocation(line: 0, scope: !20)
!27 = !DILocation(line: 9, column: 9, scope: !20)
!28 = !DILocation(line: 11, column: 9, scope: !10)
!29 = !DILocation(line: 12, column: 16, scope: !10)
!30 = !DILocation(line: 12, column: 14, scope: !10)
!31 = !DILocation(line: 12, column: 5, scope: !10)
!32 = !DILocation(line: 8, column: 29, scope: !21)
!33 = !DILocation(line: 8, column: 23, scope: !21)
!34 = distinct !{!34, !25, !35, !36, !37}
!35 = !DILocation(line: 10, column: 18, scope: !18)
!36 = !{!"llvm.loop.mustprogress"}
!37 = !{!"llvm.loop.unroll.disable"}
!38 = !DILocation(line: 10, column: 18, scope: !39)
!39 = distinct !DILexicalBlock(scope: !20, file: !8, line: 9, column: 9)
!40 = !DILocation(line: 10, column: 15, scope: !39)
!41 = !DILocation(line: 9, column: 32, scope: !39)
!42 = !DILocation(line: 9, column: 27, scope: !39)
!43 = distinct !{!43, !27, !44, !36, !37}
!44 = !DILocation(line: 10, column: 18, scope: !20)
!45 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 14, type: !11, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!46 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !47)
!47 = distinct !DILocation(line: 14, column: 25, scope: !45)
!48 = !DILocation(line: 0, scope: !10, inlinedAt: !47)
!49 = !DILocation(line: 0, scope: !18, inlinedAt: !47)
!50 = !DILocation(line: 8, column: 5, scope: !18, inlinedAt: !47)
!51 = !DILocation(line: 0, scope: !20, inlinedAt: !47)
!52 = !DILocation(line: 9, column: 9, scope: !20, inlinedAt: !47)
!53 = !DILocation(line: 8, column: 29, scope: !21, inlinedAt: !47)
!54 = !DILocation(line: 8, column: 23, scope: !21, inlinedAt: !47)
!55 = distinct !{!55, !50, !56, !36, !37}
!56 = !DILocation(line: 10, column: 18, scope: !18, inlinedAt: !47)
!57 = !DILocation(line: 10, column: 18, scope: !39, inlinedAt: !47)
!58 = !DILocation(line: 10, column: 15, scope: !39, inlinedAt: !47)
!59 = !DILocation(line: 9, column: 32, scope: !39, inlinedAt: !47)
!60 = !DILocation(line: 9, column: 27, scope: !39, inlinedAt: !47)
!61 = distinct !{!61, !52, !62, !36, !37}
!62 = !DILocation(line: 10, column: 18, scope: !20, inlinedAt: !47)
!63 = !DILocation(line: 11, column: 9, scope: !10, inlinedAt: !47)
!64 = !DILocation(line: 12, column: 16, scope: !10, inlinedAt: !47)
!65 = !DILocation(line: 12, column: 14, scope: !10, inlinedAt: !47)
!66 = !DILocation(line: 14, column: 18, scope: !45)
