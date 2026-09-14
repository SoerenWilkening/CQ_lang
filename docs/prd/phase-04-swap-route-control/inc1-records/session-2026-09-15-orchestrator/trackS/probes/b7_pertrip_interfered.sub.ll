; ModuleID = './b7_pertrip_interfered.s1.ll'
source_filename = "b7_pertrip_interfered.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !21)
    #dbg_value(i32 0, !16, !DIExpression(), !22)
  br label %2, !dbg !23

1:                                                ; preds = %2
  ret i32 %6, !dbg !24

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %6, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %7, %2 ]
    #dbg_value(i32 %3, !15, !DIExpression(), !21)
    #dbg_value(i32 %4, !16, !DIExpression(), !22)
  %h = call i32 @cqrt_alloc_i32(i32 6), !dbg !25
  call void @cqrt_ry_i32(i32 %h, double 4.000000e-01), !dbg !25
    #dbg_value(i32 %h, !18, !DIExpression(), !26)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !27
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !27
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !27
  call void @cqrt_free(i32 %h_op), !dbg !27
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !27
  %5 = add nsw i32 %m, %3, !dbg !28
    #dbg_value(i32 %5, !15, !DIExpression(), !21)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !29
    #dbg_value(i32 %h, !18, !DIExpression(), !26)
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !30
  %6 = add nsw i32 %5, %m2, !dbg !31
    #dbg_value(i32 %6, !15, !DIExpression(), !21)
  %7 = add nuw nsw i32 %4, 1, !dbg !32
    #dbg_value(i32 %7, !16, !DIExpression(), !22)
  %8 = icmp eq i32 %4, 0, !dbg !33
  br i1 %8, label %2, label %1, !dbg !23, !llvm.loop !34
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !38 {
    #dbg_value(i32 0, !15, !DIExpression(), !39)
    #dbg_value(i32 0, !16, !DIExpression(), !41)
  br label %1, !dbg !42

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %6, %1 ]
    #dbg_value(i32 %2, !15, !DIExpression(), !39)
    #dbg_value(i32 %3, !16, !DIExpression(), !41)
  %h = call i32 @cqrt_alloc_i32(i32 6), !dbg !43
  call void @cqrt_ry_i32(i32 %h, double 4.000000e-01), !dbg !43
    #dbg_value(i32 %h, !18, !DIExpression(), !44)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !45
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !45
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !45
  call void @cqrt_free(i32 %h_op), !dbg !45
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !45
  %4 = add nsw i32 %m, %2, !dbg !46
    #dbg_value(i32 %4, !15, !DIExpression(), !39)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !47
    #dbg_value(i32 %h, !18, !DIExpression(), !44)
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !48
  %5 = add nsw i32 %4, %m2, !dbg !49
    #dbg_value(i32 %5, !15, !DIExpression(), !39)
  %6 = add nuw nsw i32 %3, 1, !dbg !50
    #dbg_value(i32 %6, !16, !DIExpression(), !41)
  %7 = icmp eq i32 %3, 0, !dbg !51
  br i1 %7, label %1, label %8, !dbg !42, !llvm.loop !52

8:                                                ; preds = %1
  ret i32 %5, !dbg !54
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
!8 = !DIFile(filename: "b7_pertrip_interfered.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "a0616bca94e8b485b9a9276ad1bf99e0")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 7, type: !11, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18}
!15 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!16 = !DILocalVariable(name: "k", scope: !17, file: !8, line: 9, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!18 = !DILocalVariable(name: "u", scope: !19, file: !8, line: 10, type: !13)
!19 = distinct !DILexicalBlock(scope: !20, file: !8, line: 9, column: 33)
!20 = distinct !DILexicalBlock(scope: !17, file: !8, line: 9, column: 5)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 0, scope: !17)
!23 = !DILocation(line: 9, column: 5, scope: !17)
!24 = !DILocation(line: 15, column: 5, scope: !10)
!25 = !DILocation(line: 10, column: 17, scope: !19)
!26 = !DILocation(line: 0, scope: !19)
!27 = !DILocation(line: 11, column: 14, scope: !19)
!28 = !DILocation(line: 11, column: 11, scope: !19)
!29 = !DILocation(line: 12, column: 13, scope: !19)
!30 = !DILocation(line: 13, column: 14, scope: !19)
!31 = !DILocation(line: 13, column: 11, scope: !19)
!32 = !DILocation(line: 9, column: 28, scope: !20)
!33 = !DILocation(line: 9, column: 23, scope: !20)
!34 = distinct !{!34, !23, !35, !36, !37}
!35 = !DILocation(line: 14, column: 5, scope: !17)
!36 = !{!"llvm.loop.mustprogress"}
!37 = !{!"llvm.loop.unroll.disable"}
!38 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 17, type: !11, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!39 = !DILocation(line: 0, scope: !10, inlinedAt: !40)
!40 = distinct !DILocation(line: 17, column: 25, scope: !38)
!41 = !DILocation(line: 0, scope: !17, inlinedAt: !40)
!42 = !DILocation(line: 9, column: 5, scope: !17, inlinedAt: !40)
!43 = !DILocation(line: 10, column: 17, scope: !19, inlinedAt: !40)
!44 = !DILocation(line: 0, scope: !19, inlinedAt: !40)
!45 = !DILocation(line: 11, column: 14, scope: !19, inlinedAt: !40)
!46 = !DILocation(line: 11, column: 11, scope: !19, inlinedAt: !40)
!47 = !DILocation(line: 12, column: 13, scope: !19, inlinedAt: !40)
!48 = !DILocation(line: 13, column: 14, scope: !19, inlinedAt: !40)
!49 = !DILocation(line: 13, column: 11, scope: !19, inlinedAt: !40)
!50 = !DILocation(line: 9, column: 28, scope: !20, inlinedAt: !40)
!51 = !DILocation(line: 9, column: 23, scope: !20, inlinedAt: !40)
!52 = distinct !{!52, !42, !53, !36, !37}
!53 = !DILocation(line: 14, column: 5, scope: !17, inlinedAt: !40)
!54 = !DILocation(line: 17, column: 18, scope: !38)
