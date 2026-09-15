; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/out/w2k_noregion_invread.ora.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2k_noregion_invread.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !22
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !22
    #dbg_value(i32 %h, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
  br label %3, !dbg !25

1:                                                ; preds = %3
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !26
  %2 = add nsw i32 %m, %7, !dbg !27
  ret i32 %2, !dbg !28

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %8, %3 ]
    #dbg_value(i32 %4, !16, !DIExpression(), !23)
    #dbg_value(i32 %5, !17, !DIExpression(), !24)
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !29
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !29
    #dbg_value(i32 %h1, !19, !DIExpression(), !30)
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h1, i32 1), !dbg !31
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 1), !dbg !31
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !31
  %m5 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !32
  %6 = add i32 %m4, %4, !dbg !33
  %7 = add i32 %6, %m5, !dbg !34
    #dbg_value(i32 %7, !16, !DIExpression(), !23)
  %8 = add nuw nsw i32 %5, 1, !dbg !35
    #dbg_value(i32 %8, !17, !DIExpression(), !24)
  %9 = icmp eq i32 %5, 0, !dbg !36
  br i1 %9, label %3, label %1, !dbg !25, !llvm.loop !37
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !41 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !42
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !42
    #dbg_value(i32 %h, !15, !DIExpression(), !44)
    #dbg_value(i32 0, !16, !DIExpression(), !44)
    #dbg_value(i32 0, !17, !DIExpression(), !45)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
  br label %1, !dbg !46

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %6, %1 ]
    #dbg_value(i32 %2, !16, !DIExpression(), !44)
    #dbg_value(i32 %3, !17, !DIExpression(), !45)
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !47
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !47
    #dbg_value(i32 %h1, !19, !DIExpression(), !48)
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h1, i32 1), !dbg !49
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 1), !dbg !49
  %m = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !49
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !50
  %4 = add i32 %m, %2, !dbg !51
  %5 = add i32 %4, %m4, !dbg !52
    #dbg_value(i32 %5, !16, !DIExpression(), !44)
  %6 = add nuw nsw i32 %3, 1, !dbg !53
    #dbg_value(i32 %6, !17, !DIExpression(), !45)
  %7 = icmp eq i32 %3, 0, !dbg !54
  br i1 %7, label %1, label %8, !dbg !46, !llvm.loop !55

8:                                                ; preds = %1
  %m5 = call i32 @cqrt_measure_i32(i32 %h), !dbg !57
  %9 = add nsw i32 %m5, %5, !dbg !58
  ret i32 %9, !dbg !59
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2k_noregion_invread.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "480b45c8d804b748ad41363582d5290f")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 9, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 10, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 9, column: 33)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 9, column: 5)
!22 = !DILocation(line: 7, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 9, column: 5, scope: !18)
!26 = !DILocation(line: 13, column: 16, scope: !10)
!27 = !DILocation(line: 13, column: 14, scope: !10)
!28 = !DILocation(line: 13, column: 5, scope: !10)
!29 = !DILocation(line: 10, column: 17, scope: !20)
!30 = !DILocation(line: 0, scope: !20)
!31 = !DILocation(line: 11, column: 14, scope: !20)
!32 = !DILocation(line: 11, column: 41, scope: !20)
!33 = !DILocation(line: 11, column: 39, scope: !20)
!34 = !DILocation(line: 11, column: 11, scope: !20)
!35 = !DILocation(line: 9, column: 28, scope: !21)
!36 = !DILocation(line: 9, column: 23, scope: !21)
!37 = distinct !{!37, !25, !38, !39, !40}
!38 = !DILocation(line: 12, column: 5, scope: !18)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !{!"llvm.loop.unroll.disable"}
!41 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!42 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !43)
!43 = distinct !DILocation(line: 15, column: 25, scope: !41)
!44 = !DILocation(line: 0, scope: !10, inlinedAt: !43)
!45 = !DILocation(line: 0, scope: !18, inlinedAt: !43)
!46 = !DILocation(line: 9, column: 5, scope: !18, inlinedAt: !43)
!47 = !DILocation(line: 10, column: 17, scope: !20, inlinedAt: !43)
!48 = !DILocation(line: 0, scope: !20, inlinedAt: !43)
!49 = !DILocation(line: 11, column: 14, scope: !20, inlinedAt: !43)
!50 = !DILocation(line: 11, column: 41, scope: !20, inlinedAt: !43)
!51 = !DILocation(line: 11, column: 39, scope: !20, inlinedAt: !43)
!52 = !DILocation(line: 11, column: 11, scope: !20, inlinedAt: !43)
!53 = !DILocation(line: 9, column: 28, scope: !21, inlinedAt: !43)
!54 = !DILocation(line: 9, column: 23, scope: !21, inlinedAt: !43)
!55 = distinct !{!55, !46, !56, !39, !40}
!56 = !DILocation(line: 12, column: 5, scope: !18, inlinedAt: !43)
!57 = !DILocation(line: 13, column: 16, scope: !10, inlinedAt: !43)
!58 = !DILocation(line: 13, column: 14, scope: !10, inlinedAt: !43)
!59 = !DILocation(line: 15, column: 18, scope: !41)
