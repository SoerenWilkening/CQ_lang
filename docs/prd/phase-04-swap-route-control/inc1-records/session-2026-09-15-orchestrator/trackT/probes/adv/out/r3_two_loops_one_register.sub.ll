; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/r3_two_loops_one_register.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r3_two_loops_one_register.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !21
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !21
    #dbg_value(i32 %h, !15, !DIExpression(), !22)
    #dbg_value(i32 0, !16, !DIExpression(), !22)
    #dbg_value(i32 1, !17, !DIExpression(), !23)
  br label %1, !dbg !24

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 1, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !23)
    #dbg_value(i32 %3, !16, !DIExpression(), !22)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %2), !dbg !25
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !25
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %2), !dbg !25
  call void @cqrt_free(i32 %h_op), !dbg !25
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !25
  %4 = add nsw i32 %m, %3, !dbg !27
    #dbg_value(i32 %4, !16, !DIExpression(), !22)
  %5 = add nuw nsw i32 %2, 1, !dbg !28
    #dbg_value(i32 %5, !17, !DIExpression(), !23)
  %6 = icmp eq i32 %5, 3, !dbg !29
  br i1 %6, label %9, label %1, !dbg !24, !llvm.loop !30

7:                                                ; preds = %9
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !34
    #dbg_value(i32 %h, !15, !DIExpression(), !22)
  %m4 = call i32 @cqrt_measure_i32(i32 %h), !dbg !35
  %8 = add nsw i32 %m4, %12, !dbg !36
  ret i32 %8, !dbg !37

9:                                                ; preds = %9, %1
  %10 = phi i32 [ %13, %9 ], [ 3, %1 ]
  %11 = phi i32 [ %12, %9 ], [ %4, %1 ]
    #dbg_value(i32 %10, !19, !DIExpression(), !38)
    #dbg_value(i32 %11, !16, !DIExpression(), !22)
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %10), !dbg !39
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 1), !dbg !39
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op2, i32 %h, i32 %10), !dbg !39
  call void @cqrt_free(i32 %h_op2), !dbg !39
  %m5 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !39
  %12 = add nsw i32 %m5, %11, !dbg !41
    #dbg_value(i32 %12, !16, !DIExpression(), !22)
  %13 = add nuw nsw i32 %10, 1, !dbg !42
    #dbg_value(i32 %13, !19, !DIExpression(), !38)
  %14 = icmp eq i32 %13, 5, !dbg !43
  br i1 %14, label %7, label %9, !dbg !44, !llvm.loop !45
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !47 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !48
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !48
    #dbg_value(i32 %h, !15, !DIExpression(), !50)
    #dbg_value(i32 0, !16, !DIExpression(), !50)
    #dbg_value(i32 1, !17, !DIExpression(), !51)
  br label %1, !dbg !52

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 1, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !51)
    #dbg_value(i32 %3, !16, !DIExpression(), !50)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %2), !dbg !53
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !53
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %2), !dbg !53
  call void @cqrt_free(i32 %h_op), !dbg !53
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !53
  %4 = add nsw i32 %m, %3, !dbg !54
    #dbg_value(i32 %4, !16, !DIExpression(), !50)
  %5 = add nuw nsw i32 %2, 1, !dbg !55
    #dbg_value(i32 %5, !17, !DIExpression(), !51)
  %6 = icmp eq i32 %5, 3, !dbg !56
  br i1 %6, label %7, label %1, !dbg !52, !llvm.loop !57

7:                                                ; preds = %7, %1
  %8 = phi i32 [ %11, %7 ], [ 3, %1 ]
  %9 = phi i32 [ %10, %7 ], [ %4, %1 ]
    #dbg_value(i32 %8, !19, !DIExpression(), !59)
    #dbg_value(i32 %9, !16, !DIExpression(), !50)
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %8), !dbg !60
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 1), !dbg !60
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op2, i32 %h, i32 %8), !dbg !60
  call void @cqrt_free(i32 %h_op2), !dbg !60
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !60
  %10 = add nsw i32 %m4, %9, !dbg !61
    #dbg_value(i32 %10, !16, !DIExpression(), !50)
  %11 = add nuw nsw i32 %8, 1, !dbg !62
    #dbg_value(i32 %11, !19, !DIExpression(), !59)
  %12 = icmp eq i32 %11, 5, !dbg !63
  br i1 %12, label %13, label %7, !dbg !64, !llvm.loop !65

13:                                               ; preds = %7
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !67
    #dbg_value(i32 %h, !15, !DIExpression(), !50)
  %m5 = call i32 @cqrt_measure_i32(i32 %h), !dbg !68
  %14 = add nsw i32 %m5, %10, !dbg !69
  ret i32 %14, !dbg !70
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r3_two_loops_one_register.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "87e45a18d9733cfb8536352fce5222bc")
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
!19 = !DILocalVariable(name: "k", scope: !20, file: !8, line: 9, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!21 = !DILocation(line: 6, column: 13, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 0, scope: !18)
!24 = !DILocation(line: 8, column: 5, scope: !18)
!25 = !DILocation(line: 8, column: 39, scope: !26)
!26 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!27 = !DILocation(line: 8, column: 36, scope: !26)
!28 = !DILocation(line: 8, column: 29, scope: !26)
!29 = !DILocation(line: 8, column: 23, scope: !26)
!30 = distinct !{!30, !24, !31, !32, !33}
!31 = !DILocation(line: 8, column: 39, scope: !18)
!32 = !{!"llvm.loop.mustprogress"}
!33 = !{!"llvm.loop.unroll.disable"}
!34 = !DILocation(line: 10, column: 9, scope: !10)
!35 = !DILocation(line: 11, column: 16, scope: !10)
!36 = !DILocation(line: 11, column: 14, scope: !10)
!37 = !DILocation(line: 11, column: 5, scope: !10)
!38 = !DILocation(line: 0, scope: !20)
!39 = !DILocation(line: 9, column: 39, scope: !40)
!40 = distinct !DILexicalBlock(scope: !20, file: !8, line: 9, column: 5)
!41 = !DILocation(line: 9, column: 36, scope: !40)
!42 = !DILocation(line: 9, column: 29, scope: !40)
!43 = !DILocation(line: 9, column: 23, scope: !40)
!44 = !DILocation(line: 9, column: 5, scope: !20)
!45 = distinct !{!45, !44, !46, !32, !33}
!46 = !DILocation(line: 9, column: 39, scope: !20)
!47 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!48 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !49)
!49 = distinct !DILocation(line: 13, column: 25, scope: !47)
!50 = !DILocation(line: 0, scope: !10, inlinedAt: !49)
!51 = !DILocation(line: 0, scope: !18, inlinedAt: !49)
!52 = !DILocation(line: 8, column: 5, scope: !18, inlinedAt: !49)
!53 = !DILocation(line: 8, column: 39, scope: !26, inlinedAt: !49)
!54 = !DILocation(line: 8, column: 36, scope: !26, inlinedAt: !49)
!55 = !DILocation(line: 8, column: 29, scope: !26, inlinedAt: !49)
!56 = !DILocation(line: 8, column: 23, scope: !26, inlinedAt: !49)
!57 = distinct !{!57, !52, !58, !32, !33}
!58 = !DILocation(line: 8, column: 39, scope: !18, inlinedAt: !49)
!59 = !DILocation(line: 0, scope: !20, inlinedAt: !49)
!60 = !DILocation(line: 9, column: 39, scope: !40, inlinedAt: !49)
!61 = !DILocation(line: 9, column: 36, scope: !40, inlinedAt: !49)
!62 = !DILocation(line: 9, column: 29, scope: !40, inlinedAt: !49)
!63 = !DILocation(line: 9, column: 23, scope: !40, inlinedAt: !49)
!64 = !DILocation(line: 9, column: 5, scope: !20, inlinedAt: !49)
!65 = distinct !{!65, !64, !66, !32, !33}
!66 = !DILocation(line: 9, column: 39, scope: !20, inlinedAt: !49)
!67 = !DILocation(line: 10, column: 9, scope: !10, inlinedAt: !49)
!68 = !DILocation(line: 11, column: 16, scope: !10, inlinedAt: !49)
!69 = !DILocation(line: 11, column: 14, scope: !10, inlinedAt: !49)
!70 = !DILocation(line: 13, column: 18, scope: !47)
