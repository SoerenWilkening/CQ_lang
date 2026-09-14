; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.LkIIlW6lgk/s1.ll'
source_filename = "./v2_wg_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !22
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !22
    #dbg_value(i32 %h, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !23)
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !24
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01), !dbg !24
    #dbg_value(i32 %h2, !18, !DIExpression(), !25)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !26
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !26
  call void @cqrt_x(i32 %h_cmp1), !dbg !28
  call void @cqrt_ry_i32_controlled(i32 %h_cmp1, i32 %h2, double 2.000000e-01), !dbg !29
  call void @cqrt_x(i32 %h_cmp1), !dbg !28
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op, i32 0), !dbg !26
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !26
  call void @cqrt_free(i32 %h_op), !dbg !26
  call void @cqrt_free(i32 %h_cmp1), !dbg !28
    #dbg_value(i32 %h2, !18, !DIExpression(), !25)
  %m = call i32 @cqrt_measure_i32(i32 %h2), !dbg !30
    #dbg_value(i32 %m, !17, !DIExpression(), !23)
  %h3 = call i32 @cqrt_alloc_i32(i32 7), !dbg !31
  call void @cqrt_ry_i32(i32 %h3, double 2.500000e-01), !dbg !31
    #dbg_value(i32 %h3, !20, !DIExpression(), !32)
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h, i32 2), !dbg !33
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op4, i32 0), !dbg !33
  call void @cqrt_x(i32 %h_cmp), !dbg !35
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h3, double 2.000000e-01), !dbg !36
  call void @cqrt_x(i32 %h_cmp), !dbg !35
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op4, i32 0), !dbg !33
  call void @cq_template_and_i32_hl_unc(i32 %h_op4, i32 %h, i32 2), !dbg !33
  call void @cqrt_free(i32 %h_op4), !dbg !33
  call void @cqrt_free(i32 %h_cmp), !dbg !35
    #dbg_value(i32 %h3, !20, !DIExpression(), !32)
  %m5 = call i32 @cqrt_measure_i32(i32 %h3), !dbg !37
  %1 = add nsw i32 %m5, %m, !dbg !38
    #dbg_value(i32 %1, !17, !DIExpression(), !23)
  %m6 = call i32 @cqrt_measure_i32(i32 %h), !dbg !39
  %2 = add nsw i32 %1, %m6, !dbg !40
  ret i32 %2, !dbg !41
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !42 {
  %1 = tail call i32 @slice(), !dbg !43
  ret i32 %1, !dbg !44
}

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

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
!8 = !DIFile(filename: "v2_wg_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "cc359555365e02afe0cb5585ef2cf118")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !11, file: !11, line: 2, type: !12, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "./v2_wg_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "cc359555365e02afe0cb5585ef2cf118")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18, !20}
!16 = !DILocalVariable(name: "q", scope: !10, file: !11, line: 3, type: !14)
!17 = !DILocalVariable(name: "s", scope: !10, file: !11, line: 4, type: !14)
!18 = !DILocalVariable(name: "r", scope: !19, file: !11, line: 5, type: !14)
!19 = distinct !DILexicalBlock(scope: !10, file: !11, line: 5, column: 5)
!20 = !DILocalVariable(name: "r", scope: !21, file: !11, line: 6, type: !14)
!21 = distinct !DILexicalBlock(scope: !10, file: !11, line: 6, column: 5)
!22 = !DILocation(line: 3, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 5, column: 15, scope: !19)
!25 = !DILocation(line: 0, scope: !19)
!26 = !DILocation(line: 5, column: 47, scope: !27)
!27 = distinct !DILexicalBlock(scope: !19, file: !11, line: 5, column: 38)
!28 = !DILocation(line: 5, column: 38, scope: !19)
!29 = !DILocation(line: 5, column: 56, scope: !27)
!30 = !DILocation(line: 5, column: 79, scope: !19)
!31 = !DILocation(line: 6, column: 15, scope: !21)
!32 = !DILocation(line: 0, scope: !21)
!33 = !DILocation(line: 6, column: 47, scope: !34)
!34 = distinct !DILexicalBlock(scope: !21, file: !11, line: 6, column: 38)
!35 = !DILocation(line: 6, column: 38, scope: !21)
!36 = !DILocation(line: 6, column: 56, scope: !34)
!37 = !DILocation(line: 6, column: 79, scope: !21)
!38 = !DILocation(line: 6, column: 76, scope: !21)
!39 = !DILocation(line: 7, column: 16, scope: !10)
!40 = !DILocation(line: 7, column: 14, scope: !10)
!41 = !DILocation(line: 7, column: 5, scope: !10)
!42 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 9, type: !12, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!43 = !DILocation(line: 9, column: 25, scope: !42)
!44 = !DILocation(line: 9, column: 18, scope: !42)
