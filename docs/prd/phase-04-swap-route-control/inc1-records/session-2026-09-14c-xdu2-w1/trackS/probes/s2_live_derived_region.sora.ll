; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.rLWLsW0k5H/s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/s2_live_derived_region.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !20
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !20
    #dbg_value(i32 %h, !15, !DIExpression(), !21)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3), !dbg !22
    #dbg_value(i32 %h_op, !16, !DIExpression(), !21)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
    #dbg_value(i32 1, !18, !DIExpression(), !23)
  br label %2, !dbg !24

1:                                                ; preds = %2
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !25
    #dbg_value(i32 %h, !15, !DIExpression(), !21)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !26
  ret i32 %m, !dbg !27

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %5, %2 ]
    #dbg_value(i32 %3, !18, !DIExpression(), !23)
  %4 = shl nuw nsw i32 1, %3, !dbg !28
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 %4), !dbg !28
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 0), !dbg !28
  call void @cqrt_x(i32 %h_cmp), !dbg !31
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01), !dbg !31, !cq.branchphase !32
  call void @cqrt_x(i32 %h_cmp), !dbg !31
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 0), !dbg !28
  call void @cqrt_free(i32 %h_cmp), !dbg !31
  %5 = add nuw nsw i32 %3, 1, !dbg !33
    #dbg_value(i32 %5, !18, !DIExpression(), !23)
  %6 = icmp eq i32 %5, 3, !dbg !34
  br i1 %6, label %1, label %2, !dbg !24, !llvm.loop !35
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !39 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !40
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !40
    #dbg_value(i32 %h, !15, !DIExpression(), !42)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3), !dbg !43
    #dbg_value(i32 %h_op, !16, !DIExpression(), !42)
    #dbg_value(i32 0, !17, !DIExpression(), !42)
    #dbg_value(i32 1, !18, !DIExpression(), !44)
  br label %1, !dbg !45

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 1, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !18, !DIExpression(), !44)
  %3 = shl nuw nsw i32 1, %2, !dbg !46
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 %3), !dbg !46
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 0), !dbg !46
  call void @cqrt_x(i32 %h_cmp), !dbg !47
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01), !dbg !47, !cq.branchphase !32
  call void @cqrt_x(i32 %h_cmp), !dbg !47
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 0), !dbg !46
  call void @cqrt_free(i32 %h_cmp), !dbg !47
  %4 = add nuw nsw i32 %2, 1, !dbg !48
    #dbg_value(i32 %4, !18, !DIExpression(), !44)
  %5 = icmp eq i32 %4, 3, !dbg !49
  br i1 %5, label %6, label %1, !dbg !45, !llvm.loop !50

6:                                                ; preds = %1
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !52
    #dbg_value(i32 %h, !15, !DIExpression(), !42)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !53
  ret i32 %m, !dbg !54
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/s2_live_derived_region.c", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "179f5d85972a16c18b475201b41dac12")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "p", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 9, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 10, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 5)
!20 = !DILocation(line: 7, column: 13, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 8, column: 15, scope: !10)
!23 = !DILocation(line: 0, scope: !19)
!24 = !DILocation(line: 10, column: 5, scope: !19)
!25 = !DILocation(line: 12, column: 9, scope: !10)
!26 = !DILocation(line: 13, column: 16, scope: !10)
!27 = !DILocation(line: 13, column: 5, scope: !10)
!28 = !DILocation(line: 11, column: 22, scope: !29)
!29 = distinct !DILexicalBlock(scope: !30, file: !8, line: 11, column: 13)
!30 = distinct !DILexicalBlock(scope: !19, file: !8, line: 10, column: 5)
!31 = !DILocation(line: 11, column: 27, scope: !29)
!32 = !{}
!33 = !DILocation(line: 10, column: 29, scope: !30)
!34 = !DILocation(line: 10, column: 23, scope: !30)
!35 = distinct !{!35, !24, !36, !37, !38}
!36 = !DILocation(line: 11, column: 37, scope: !19)
!37 = !{!"llvm.loop.mustprogress"}
!38 = !{!"llvm.loop.unroll.disable"}
!39 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!40 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !41)
!41 = distinct !DILocation(line: 15, column: 25, scope: !39)
!42 = !DILocation(line: 0, scope: !10, inlinedAt: !41)
!43 = !DILocation(line: 8, column: 15, scope: !10, inlinedAt: !41)
!44 = !DILocation(line: 0, scope: !19, inlinedAt: !41)
!45 = !DILocation(line: 10, column: 5, scope: !19, inlinedAt: !41)
!46 = !DILocation(line: 11, column: 22, scope: !29, inlinedAt: !41)
!47 = !DILocation(line: 11, column: 27, scope: !29, inlinedAt: !41)
!48 = !DILocation(line: 10, column: 29, scope: !30, inlinedAt: !41)
!49 = !DILocation(line: 10, column: 23, scope: !30, inlinedAt: !41)
!50 = distinct !{!50, !45, !51, !37, !38}
!51 = !DILocation(line: 11, column: 37, scope: !19, inlinedAt: !41)
!52 = !DILocation(line: 12, column: 9, scope: !10, inlinedAt: !41)
!53 = !DILocation(line: 13, column: 16, scope: !10, inlinedAt: !41)
!54 = !DILocation(line: 15, column: 18, scope: !39)
