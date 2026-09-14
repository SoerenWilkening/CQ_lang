; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.eeVF02hcF6/s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/mutant_s3_un_angle.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !16
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !16
    #dbg_value(i32 %h, !15, !DIExpression(), !17)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 2), !dbg !18
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !18
  call void @cqrt_x(i32 %h_cmp1), !dbg !20
  call void @cqrt_rz_i1(i32 %h_cmp1, double 3.100000e-01), !dbg !20, !cq.branchphase !21
  call void @cqrt_x(i32 %h_cmp1), !dbg !20
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op, i32 0), !dbg !18
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 2), !dbg !18
  call void @cqrt_free(i32 %h_op), !dbg !18
  call void @cqrt_free(i32 %h_cmp1), !dbg !20
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h, i32 4), !dbg !22
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op2, i32 0), !dbg !22
  call void @cqrt_x(i32 %h_cmp), !dbg !24
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.100000e-01), !dbg !24, !cq.branchphase !21
  call void @cqrt_x(i32 %h_cmp), !dbg !24
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op2, i32 0), !dbg !22
  call void @cq_template_and_i32_hl_unc(i32 %h_op2, i32 %h, i32 4), !dbg !22
  call void @cqrt_free(i32 %h_op2), !dbg !22
  call void @cqrt_free(i32 %h_cmp), !dbg !24
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !25
    #dbg_value(i32 %h, !15, !DIExpression(), !17)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !26
  ret i32 %m, !dbg !27
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !28 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !29
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !29
    #dbg_value(i32 %h, !15, !DIExpression(), !31)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 2), !dbg !32
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !32
  call void @cqrt_x(i32 %h_cmp1), !dbg !33
  call void @cqrt_rz_i1(i32 %h_cmp1, double 3.100000e-01), !dbg !33, !cq.branchphase !21
  call void @cqrt_x(i32 %h_cmp1), !dbg !33
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op, i32 0), !dbg !32
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 2), !dbg !32
  call void @cqrt_free(i32 %h_op), !dbg !32
  call void @cqrt_free(i32 %h_cmp1), !dbg !33
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h, i32 4), !dbg !34
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op2, i32 0), !dbg !34
  call void @cqrt_x(i32 %h_cmp), !dbg !35
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.100000e-01), !dbg !35, !cq.branchphase !21
  call void @cqrt_x(i32 %h_cmp), !dbg !35
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op2, i32 0), !dbg !34
  call void @cq_template_and_i32_hl_unc(i32 %h_op2, i32 %h, i32 4), !dbg !34
  call void @cqrt_free(i32 %h_op2), !dbg !34
  call void @cqrt_free(i32 %h_cmp), !dbg !35
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !36
    #dbg_value(i32 %h, !15, !DIExpression(), !31)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !37
  ret i32 %m, !dbg !38
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/mutant_s3_un_angle.c", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "df92cb25d2325fdaafe0a448c2781942")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocation(line: 4, column: 13, scope: !10)
!17 = !DILocation(line: 0, scope: !10)
!18 = !DILocation(line: 5, column: 18, scope: !19)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 9)
!20 = !DILocation(line: 5, column: 23, scope: !19)
!21 = !{}
!22 = !DILocation(line: 6, column: 18, scope: !23)
!23 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 9)
!24 = !DILocation(line: 6, column: 23, scope: !23)
!25 = !DILocation(line: 7, column: 9, scope: !10)
!26 = !DILocation(line: 8, column: 12, scope: !10)
!27 = !DILocation(line: 8, column: 5, scope: !10)
!28 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!29 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !30)
!30 = distinct !DILocation(line: 10, column: 25, scope: !28)
!31 = !DILocation(line: 0, scope: !10, inlinedAt: !30)
!32 = !DILocation(line: 5, column: 18, scope: !19, inlinedAt: !30)
!33 = !DILocation(line: 5, column: 23, scope: !19, inlinedAt: !30)
!34 = !DILocation(line: 6, column: 18, scope: !23, inlinedAt: !30)
!35 = !DILocation(line: 6, column: 23, scope: !23, inlinedAt: !30)
!36 = !DILocation(line: 7, column: 9, scope: !10, inlinedAt: !30)
!37 = !DILocation(line: 8, column: 12, scope: !10, inlinedAt: !30)
!38 = !DILocation(line: 10, column: 18, scope: !28)
