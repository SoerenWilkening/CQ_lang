; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.rmr4BzSlOh/s1.ll'
source_filename = "./w2k_noregion_invread.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !23
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !23
    #dbg_value(i32 %h, !16, !DIExpression(), !24)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
    #dbg_value(i32 0, !18, !DIExpression(), !25)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
  br label %3, !dbg !26

1:                                                ; preds = %3
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !27
  %2 = add nsw i32 %m, %7, !dbg !28
  ret i32 %2, !dbg !29

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %8, %3 ]
    #dbg_value(i32 %4, !17, !DIExpression(), !24)
    #dbg_value(i32 %5, !18, !DIExpression(), !25)
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !30
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !30
    #dbg_value(i32 %h1, !20, !DIExpression(), !31)
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h1, i32 1), !dbg !32
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 1), !dbg !32
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !32
  %m5 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !33
  %6 = add i32 %m4, %4, !dbg !34
  %7 = add i32 %6, %m5, !dbg !35
    #dbg_value(i32 %7, !17, !DIExpression(), !24)
  %8 = add nuw nsw i32 %5, 1, !dbg !36
    #dbg_value(i32 %8, !18, !DIExpression(), !25)
  %9 = icmp eq i32 %5, 0, !dbg !37
  br i1 %9, label %3, label %1, !dbg !26, !llvm.loop !38
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !42 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !43
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !43
    #dbg_value(i32 %h, !16, !DIExpression(), !45)
    #dbg_value(i32 0, !17, !DIExpression(), !45)
    #dbg_value(i32 0, !18, !DIExpression(), !46)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
  br label %1, !dbg !47

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %6, %1 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !45)
    #dbg_value(i32 %3, !18, !DIExpression(), !46)
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !48
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !48
    #dbg_value(i32 %h1, !20, !DIExpression(), !49)
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h1, i32 1), !dbg !50
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 1), !dbg !50
  %m = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !50
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !51
  %4 = add i32 %m, %2, !dbg !52
  %5 = add i32 %4, %m4, !dbg !53
    #dbg_value(i32 %5, !17, !DIExpression(), !45)
  %6 = add nuw nsw i32 %3, 1, !dbg !54
    #dbg_value(i32 %6, !18, !DIExpression(), !46)
  %7 = icmp eq i32 %3, 0, !dbg !55
  br i1 %7, label %1, label %8, !dbg !47, !llvm.loop !56

8:                                                ; preds = %1
  %m5 = call i32 @cqrt_measure_i32(i32 %h), !dbg !58
  %9 = add nsw i32 %m5, %5, !dbg !59
  ret i32 %9, !dbg !60
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
!8 = !DIFile(filename: "w2k_noregion_invread.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "480b45c8d804b748ad41363582d5290f")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !11, file: !11, line: 6, type: !12, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "./w2k_noregion_invread.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "480b45c8d804b748ad41363582d5290f")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18, !20}
!16 = !DILocalVariable(name: "y", scope: !10, file: !11, line: 7, type: !14)
!17 = !DILocalVariable(name: "s", scope: !10, file: !11, line: 8, type: !14)
!18 = !DILocalVariable(name: "k", scope: !19, file: !11, line: 9, type: !14)
!19 = distinct !DILexicalBlock(scope: !10, file: !11, line: 9, column: 5)
!20 = !DILocalVariable(name: "u", scope: !21, file: !11, line: 10, type: !14)
!21 = distinct !DILexicalBlock(scope: !22, file: !11, line: 9, column: 33)
!22 = distinct !DILexicalBlock(scope: !19, file: !11, line: 9, column: 5)
!23 = !DILocation(line: 7, column: 13, scope: !10)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 0, scope: !19)
!26 = !DILocation(line: 9, column: 5, scope: !19)
!27 = !DILocation(line: 13, column: 16, scope: !10)
!28 = !DILocation(line: 13, column: 14, scope: !10)
!29 = !DILocation(line: 13, column: 5, scope: !10)
!30 = !DILocation(line: 10, column: 17, scope: !21)
!31 = !DILocation(line: 0, scope: !21)
!32 = !DILocation(line: 11, column: 14, scope: !21)
!33 = !DILocation(line: 11, column: 41, scope: !21)
!34 = !DILocation(line: 11, column: 39, scope: !21)
!35 = !DILocation(line: 11, column: 11, scope: !21)
!36 = !DILocation(line: 9, column: 28, scope: !22)
!37 = !DILocation(line: 9, column: 23, scope: !22)
!38 = distinct !{!38, !26, !39, !40, !41}
!39 = !DILocation(line: 12, column: 5, scope: !19)
!40 = !{!"llvm.loop.mustprogress"}
!41 = !{!"llvm.loop.unroll.disable"}
!42 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 15, type: !12, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!43 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !44)
!44 = distinct !DILocation(line: 15, column: 25, scope: !42)
!45 = !DILocation(line: 0, scope: !10, inlinedAt: !44)
!46 = !DILocation(line: 0, scope: !19, inlinedAt: !44)
!47 = !DILocation(line: 9, column: 5, scope: !19, inlinedAt: !44)
!48 = !DILocation(line: 10, column: 17, scope: !21, inlinedAt: !44)
!49 = !DILocation(line: 0, scope: !21, inlinedAt: !44)
!50 = !DILocation(line: 11, column: 14, scope: !21, inlinedAt: !44)
!51 = !DILocation(line: 11, column: 41, scope: !21, inlinedAt: !44)
!52 = !DILocation(line: 11, column: 39, scope: !21, inlinedAt: !44)
!53 = !DILocation(line: 11, column: 11, scope: !21, inlinedAt: !44)
!54 = !DILocation(line: 9, column: 28, scope: !22, inlinedAt: !44)
!55 = !DILocation(line: 9, column: 23, scope: !22, inlinedAt: !44)
!56 = distinct !{!56, !47, !57, !40, !41}
!57 = !DILocation(line: 12, column: 5, scope: !19, inlinedAt: !44)
!58 = !DILocation(line: 13, column: 16, scope: !10, inlinedAt: !44)
!59 = !DILocation(line: 13, column: 14, scope: !10, inlinedAt: !44)
!60 = !DILocation(line: 15, column: 18, scope: !42)
