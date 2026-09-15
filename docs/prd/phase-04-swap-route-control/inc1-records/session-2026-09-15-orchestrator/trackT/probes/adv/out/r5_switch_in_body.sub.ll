; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/r5_switch_in_body.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r5_switch_in_body.c"
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
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !30
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !30
    #dbg_value(i32 %h1, !19, !DIExpression(), !31)
  %6 = shl nuw nsw i32 1, %4, !dbg !32
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 %6), !dbg !32
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !32
  call void @cqrt_x(i32 %h_cmp), !dbg !34
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01), !dbg !34, !cq.branchphase !35
  call void @cqrt_x(i32 %h_cmp), !dbg !34
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 0), !dbg !32
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 %6), !dbg !32
  call void @cqrt_free(i32 %h_op), !dbg !32
  call void @cqrt_free(i32 %h_cmp), !dbg !34
  %m2 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !36
  %7 = add nsw i32 %m2, %5, !dbg !37
    #dbg_value(i32 %7, !16, !DIExpression(), !23)
  %8 = add nuw nsw i32 %4, 1, !dbg !38
    #dbg_value(i32 %8, !17, !DIExpression(), !24)
  %9 = icmp eq i32 %8, 3, !dbg !39
  br i1 %9, label %1, label %3, !dbg !25, !llvm.loop !40
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !44 {
  %1 = tail call i32 @slice(), !dbg !45
  ret i32 %1, !dbg !46
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r5_switch_in_body.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "2415497289726a4f8f6aec63872a450b")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 5, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 6, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 7, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 7, column: 5)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 8, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 7, column: 34)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 7, column: 5)
!22 = !DILocation(line: 5, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 7, column: 5, scope: !18)
!26 = !DILocation(line: 12, column: 9, scope: !10)
!27 = !DILocation(line: 13, column: 16, scope: !10)
!28 = !DILocation(line: 13, column: 14, scope: !10)
!29 = !DILocation(line: 13, column: 5, scope: !10)
!30 = !DILocation(line: 8, column: 17, scope: !20)
!31 = !DILocation(line: 0, scope: !20)
!32 = !DILocation(line: 9, column: 22, scope: !33)
!33 = distinct !DILexicalBlock(scope: !20, file: !8, line: 9, column: 13)
!34 = !DILocation(line: 9, column: 27, scope: !33)
!35 = !{}
!36 = !DILocation(line: 10, column: 14, scope: !20)
!37 = !DILocation(line: 10, column: 11, scope: !20)
!38 = !DILocation(line: 7, column: 29, scope: !21)
!39 = !DILocation(line: 7, column: 23, scope: !21)
!40 = distinct !{!40, !25, !41, !42, !43}
!41 = !DILocation(line: 11, column: 5, scope: !18)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!45 = !DILocation(line: 15, column: 25, scope: !44)
!46 = !DILocation(line: 15, column: 18, scope: !44)
