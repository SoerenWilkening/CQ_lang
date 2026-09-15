; ModuleID = './s3_live_rootmint_region.s1.ll'
source_filename = "s3_live_rootmint_region.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !18
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !18
    #dbg_value(i32 %h, !15, !DIExpression(), !19)
    #dbg_value(i32 1, !16, !DIExpression(), !20)
  br label %2, !dbg !21

1:                                                ; preds = %2
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !22
    #dbg_value(i32 %h, !15, !DIExpression(), !19)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !23
  ret i32 %m, !dbg !24

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 1, %0 ], [ %5, %2 ]
    #dbg_value(i32 %3, !16, !DIExpression(), !20)
  %4 = shl nuw nsw i32 1, %3, !dbg !25
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 %4), !dbg !25
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !25
  call void @cqrt_x(i32 %h_cmp), !dbg !28
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01), !dbg !28, !cq.branchphase !29
  call void @cqrt_x(i32 %h_cmp), !dbg !28
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 0), !dbg !25
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 %4), !dbg !25
  call void @cqrt_free(i32 %h_op), !dbg !25
  call void @cqrt_free(i32 %h_cmp), !dbg !28
  %5 = add nuw nsw i32 %3, 1, !dbg !30
    #dbg_value(i32 %5, !16, !DIExpression(), !20)
  %6 = icmp eq i32 %5, 3, !dbg !31
  br i1 %6, label %1, label %2, !dbg !21, !llvm.loop !32
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !36 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !37
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !37
    #dbg_value(i32 %h, !15, !DIExpression(), !39)
    #dbg_value(i32 1, !16, !DIExpression(), !40)
  br label %1, !dbg !41

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 1, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !16, !DIExpression(), !40)
  %3 = shl nuw nsw i32 1, %2, !dbg !42
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 %3), !dbg !42
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !42
  call void @cqrt_x(i32 %h_cmp), !dbg !43
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01), !dbg !43, !cq.branchphase !29
  call void @cqrt_x(i32 %h_cmp), !dbg !43
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 0), !dbg !42
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 %3), !dbg !42
  call void @cqrt_free(i32 %h_op), !dbg !42
  call void @cqrt_free(i32 %h_cmp), !dbg !43
  %4 = add nuw nsw i32 %2, 1, !dbg !44
    #dbg_value(i32 %4, !16, !DIExpression(), !40)
  %5 = icmp eq i32 %4, 3, !dbg !45
  br i1 %5, label %6, label %1, !dbg !41, !llvm.loop !46

6:                                                ; preds = %1
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !48
    #dbg_value(i32 %h, !15, !DIExpression(), !39)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !49
  ret i32 %m, !dbg !50
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

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
!8 = !DIFile(filename: "s3_live_rootmint_region.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "c97d6c736b8ef5f9435837ab194802e5")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "k", scope: !17, file: !8, line: 8, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!18 = !DILocation(line: 7, column: 13, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 0, scope: !17)
!21 = !DILocation(line: 8, column: 5, scope: !17)
!22 = !DILocation(line: 10, column: 9, scope: !10)
!23 = !DILocation(line: 11, column: 12, scope: !10)
!24 = !DILocation(line: 11, column: 5, scope: !10)
!25 = !DILocation(line: 9, column: 22, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !8, line: 9, column: 13)
!27 = distinct !DILexicalBlock(scope: !17, file: !8, line: 8, column: 5)
!28 = !DILocation(line: 9, column: 27, scope: !26)
!29 = !{}
!30 = !DILocation(line: 8, column: 29, scope: !27)
!31 = !DILocation(line: 8, column: 23, scope: !27)
!32 = distinct !{!32, !21, !33, !34, !35}
!33 = !DILocation(line: 9, column: 37, scope: !17)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.unroll.disable"}
!36 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!37 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !38)
!38 = distinct !DILocation(line: 13, column: 25, scope: !36)
!39 = !DILocation(line: 0, scope: !10, inlinedAt: !38)
!40 = !DILocation(line: 0, scope: !17, inlinedAt: !38)
!41 = !DILocation(line: 8, column: 5, scope: !17, inlinedAt: !38)
!42 = !DILocation(line: 9, column: 22, scope: !26, inlinedAt: !38)
!43 = !DILocation(line: 9, column: 27, scope: !26, inlinedAt: !38)
!44 = !DILocation(line: 8, column: 29, scope: !27, inlinedAt: !38)
!45 = !DILocation(line: 8, column: 23, scope: !27, inlinedAt: !38)
!46 = distinct !{!46, !41, !47, !34, !35}
!47 = !DILocation(line: 9, column: 37, scope: !17, inlinedAt: !38)
!48 = !DILocation(line: 10, column: 9, scope: !10, inlinedAt: !38)
!49 = !DILocation(line: 11, column: 12, scope: !10, inlinedAt: !38)
!50 = !DILocation(line: 13, column: 18, scope: !36)
