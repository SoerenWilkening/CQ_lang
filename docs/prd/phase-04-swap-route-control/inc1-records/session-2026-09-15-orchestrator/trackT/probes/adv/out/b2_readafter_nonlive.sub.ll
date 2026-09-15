; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/b2_readafter_nonlive.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/b2_readafter_nonlive.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !20
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !20
    #dbg_value(i32 %h, !15, !DIExpression(), !21)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !22
    #dbg_value(i32 %h_op, !16, !DIExpression(), !21)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
    #dbg_value(i32 1, !18, !DIExpression(), !23)
  br label %4, !dbg !24

1:                                                ; preds = %4
  %h_op1 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 1), !dbg !25
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !25
  %2 = add nsw i32 %m, %8, !dbg !26
  %m4 = call i32 @cqrt_measure_i32(i32 %h), !dbg !27
  %3 = add nsw i32 %2, %m4, !dbg !28
  ret i32 %3, !dbg !29

4:                                                ; preds = %4, %0
  %5 = phi i32 [ 1, %0 ], [ %9, %4 ]
  %6 = phi i32 [ 0, %0 ], [ %8, %4 ]
    #dbg_value(i32 %5, !18, !DIExpression(), !23)
    #dbg_value(i32 %6, !17, !DIExpression(), !21)
  %m5 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !30
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %5), !dbg !32
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 1), !dbg !32
  %m6 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !32
  %7 = add i32 %m5, %6, !dbg !33
  %8 = add i32 %7, %m6, !dbg !34
    #dbg_value(i32 %8, !17, !DIExpression(), !21)
  %9 = add nuw nsw i32 %5, 1, !dbg !35
    #dbg_value(i32 %9, !18, !DIExpression(), !23)
  %10 = icmp eq i32 %9, 3, !dbg !36
  br i1 %10, label %1, label %4, !dbg !24, !llvm.loop !37
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !41 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !42
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !42
    #dbg_value(i32 %h, !15, !DIExpression(), !44)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !45
    #dbg_value(i32 %h_op, !16, !DIExpression(), !44)
    #dbg_value(i32 0, !17, !DIExpression(), !44)
    #dbg_value(i32 1, !18, !DIExpression(), !46)
  br label %1, !dbg !47

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 1, %0 ], [ %6, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %5, %1 ]
    #dbg_value(i32 %2, !18, !DIExpression(), !46)
    #dbg_value(i32 %3, !17, !DIExpression(), !44)
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !48
  %h_op1 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %2), !dbg !49
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op1, i32 1), !dbg !49
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !49
  %4 = add i32 %m, %3, !dbg !50
  %5 = add i32 %4, %m4, !dbg !51
    #dbg_value(i32 %5, !17, !DIExpression(), !44)
  %6 = add nuw nsw i32 %2, 1, !dbg !52
    #dbg_value(i32 %6, !18, !DIExpression(), !46)
  %7 = icmp eq i32 %6, 3, !dbg !53
  br i1 %7, label %8, label %1, !dbg !47, !llvm.loop !54

8:                                                ; preds = %1
  %h_op3 = call i32 @cq_template_add_i32_hl(i32 %h_op, i32 1), !dbg !56
  %m5 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !56
  %9 = add nsw i32 %m5, %5, !dbg !57
  %m6 = call i32 @cqrt_measure_i32(i32 %h), !dbg !58
  %10 = add nsw i32 %9, %m6, !dbg !59
  ret i32 %10, !dbg !60
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/b2_readafter_nonlive.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "048c9f874b69ee6b3338084e1a408c40")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 9, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!20 = !DILocation(line: 6, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 7, column: 15, scope: !10)
!23 = !DILocation(line: 0, scope: !19)
!24 = !DILocation(line: 9, column: 5, scope: !19)
!25 = !DILocation(line: 11, column: 16, scope: !10)
!26 = !DILocation(line: 11, column: 14, scope: !10)
!27 = !DILocation(line: 11, column: 36, scope: !10)
!28 = !DILocation(line: 11, column: 34, scope: !10)
!29 = !DILocation(line: 11, column: 5, scope: !10)
!30 = !DILocation(line: 10, column: 14, scope: !31)
!31 = distinct !DILexicalBlock(scope: !19, file: !8, line: 9, column: 5)
!32 = !DILocation(line: 10, column: 30, scope: !31)
!33 = !DILocation(line: 10, column: 28, scope: !31)
!34 = !DILocation(line: 10, column: 11, scope: !31)
!35 = !DILocation(line: 9, column: 29, scope: !31)
!36 = !DILocation(line: 9, column: 23, scope: !31)
!37 = distinct !{!37, !24, !38, !39, !40}
!38 = !DILocation(line: 10, column: 30, scope: !19)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !{!"llvm.loop.unroll.disable"}
!41 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!42 = !DILocation(line: 6, column: 13, scope: !10, inlinedAt: !43)
!43 = distinct !DILocation(line: 13, column: 25, scope: !41)
!44 = !DILocation(line: 0, scope: !10, inlinedAt: !43)
!45 = !DILocation(line: 7, column: 15, scope: !10, inlinedAt: !43)
!46 = !DILocation(line: 0, scope: !19, inlinedAt: !43)
!47 = !DILocation(line: 9, column: 5, scope: !19, inlinedAt: !43)
!48 = !DILocation(line: 10, column: 14, scope: !31, inlinedAt: !43)
!49 = !DILocation(line: 10, column: 30, scope: !31, inlinedAt: !43)
!50 = !DILocation(line: 10, column: 28, scope: !31, inlinedAt: !43)
!51 = !DILocation(line: 10, column: 11, scope: !31, inlinedAt: !43)
!52 = !DILocation(line: 9, column: 29, scope: !31, inlinedAt: !43)
!53 = !DILocation(line: 9, column: 23, scope: !31, inlinedAt: !43)
!54 = distinct !{!54, !47, !55, !39, !40}
!55 = !DILocation(line: 10, column: 30, scope: !19, inlinedAt: !43)
!56 = !DILocation(line: 11, column: 16, scope: !10, inlinedAt: !43)
!57 = !DILocation(line: 11, column: 14, scope: !10, inlinedAt: !43)
!58 = !DILocation(line: 11, column: 36, scope: !10, inlinedAt: !43)
!59 = !DILocation(line: 11, column: 34, scope: !10, inlinedAt: !43)
!60 = !DILocation(line: 13, column: 18, scope: !41)
