; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.S1rlVDnC3Z/s1.ll'
source_filename = "./w2h_phase_inloop_invread_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !22
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !22
    #dbg_value(i32 %h, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !23)
  %h2 = call i32 @cqrt_alloc_i32(i32 6), !dbg !24
  call void @cqrt_ry_i32(i32 %h2, double 4.000000e-01), !dbg !24
    #dbg_value(i32 %h2, !18, !DIExpression(), !25)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h2, i32 2), !dbg !26
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !26
  call void @cqrt_x(i32 %h_cmp1), !dbg !28
  call void @cqrt_rz_i1(i32 %h_cmp1, double 3.000000e-01), !dbg !28, !cq.branchphase !29
  call void @cqrt_x(i32 %h_cmp1), !dbg !28
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op, i32 0), !dbg !26
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h2, i32 2), !dbg !26
  call void @cqrt_free(i32 %h_op), !dbg !26
  call void @cqrt_free(i32 %h_cmp1), !dbg !28
  %h_op4 = call i32 @cq_template_lshr_i32_hl(i32 %h2, i32 2), !dbg !30
  %h_op5 = call i32 @cq_template_and_i32_hl(i32 %h_op4, i32 1), !dbg !30
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op4, i32 %h2, i32 2), !dbg !30
  call void @cqrt_free(i32 %h_op4), !dbg !30
  %m = call i32 @cqrt_measure_i32(i32 %h_op5), !dbg !30
  %h_op6 = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !31
  %m10 = call i32 @cqrt_measure_i32(i32 %h_op6), !dbg !31
    #dbg_value(!DIArgList(i32 %m, i32 %m10), !17, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !23)
  %h3 = call i32 @cqrt_alloc_i32(i32 6), !dbg !32
  call void @cqrt_ry_i32(i32 %h3, double 4.000000e-01), !dbg !32
    #dbg_value(i32 %h3, !20, !DIExpression(), !33)
  %h_op7 = call i32 @cq_template_and_i32_hl(i32 %h3, i32 2), !dbg !34
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op7, i32 0), !dbg !34
  call void @cqrt_x(i32 %h_cmp), !dbg !36
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01), !dbg !36, !cq.branchphase !29
  call void @cqrt_x(i32 %h_cmp), !dbg !36
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op7, i32 0), !dbg !34
  call void @cq_template_and_i32_hl_unc(i32 %h_op7, i32 %h3, i32 2), !dbg !34
  call void @cqrt_free(i32 %h_op7), !dbg !34
  call void @cqrt_free(i32 %h_cmp), !dbg !36
    #dbg_value(i32 poison, !17, !DIExpression(), !23)
  %h_op8 = call i32 @cq_template_lshr_i32_hl(i32 %h3, i32 2), !dbg !37
  %h_op9 = call i32 @cq_template_and_i32_hl(i32 %h_op8, i32 1), !dbg !37
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op8, i32 %h3, i32 2), !dbg !37
  call void @cqrt_free(i32 %h_op8), !dbg !37
  %m11 = call i32 @cqrt_measure_i32(i32 %h_op9), !dbg !37
  %m12 = call i32 @cqrt_measure_i32(i32 %h_op6), !dbg !38
    #dbg_value(i32 %3, !17, !DIExpression(), !23)
  %m13 = call i32 @cqrt_measure_i32(i32 %h), !dbg !39
  %1 = add i32 %m10, %m, !dbg !40
  %2 = add i32 %1, %m11, !dbg !41
  %3 = add i32 %2, %m12, !dbg !42
  %4 = add nsw i32 %3, %m13, !dbg !43
  ret i32 %4, !dbg !44
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !45 {
  %1 = tail call i32 @slice(), !dbg !46
  ret i32 %1, !dbg !47
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

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
!8 = !DIFile(filename: "w2h_phase_inloop_invread_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "b6937792b609ac9d7b2222148b7814c3")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !11, file: !11, line: 3, type: !12, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "./w2h_phase_inloop_invread_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "b6937792b609ac9d7b2222148b7814c3")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18, !20}
!16 = !DILocalVariable(name: "y", scope: !10, file: !11, line: 4, type: !14)
!17 = !DILocalVariable(name: "s", scope: !10, file: !11, line: 5, type: !14)
!18 = !DILocalVariable(name: "u", scope: !19, file: !11, line: 6, type: !14)
!19 = distinct !DILexicalBlock(scope: !10, file: !11, line: 6, column: 5)
!20 = !DILocalVariable(name: "u", scope: !21, file: !11, line: 8, type: !14)
!21 = distinct !DILexicalBlock(scope: !10, file: !11, line: 8, column: 5)
!22 = !DILocation(line: 4, column: 14, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 6, column: 15, scope: !19)
!25 = !DILocation(line: 0, scope: !19)
!26 = !DILocation(line: 6, column: 46, scope: !27)
!27 = distinct !DILexicalBlock(scope: !19, file: !11, line: 6, column: 37)
!28 = !DILocation(line: 6, column: 51, scope: !27)
!29 = !{}
!30 = !DILocation(line: 7, column: 12, scope: !19)
!31 = !DILocation(line: 7, column: 39, scope: !19)
!32 = !DILocation(line: 8, column: 15, scope: !21)
!33 = !DILocation(line: 0, scope: !21)
!34 = !DILocation(line: 8, column: 46, scope: !35)
!35 = distinct !DILexicalBlock(scope: !21, file: !11, line: 8, column: 37)
!36 = !DILocation(line: 8, column: 51, scope: !35)
!37 = !DILocation(line: 9, column: 12, scope: !21)
!38 = !DILocation(line: 9, column: 39, scope: !21)
!39 = !DILocation(line: 10, column: 16, scope: !10)
!40 = !DILocation(line: 9, column: 37, scope: !21)
!41 = !DILocation(line: 7, column: 37, scope: !19)
!42 = !DILocation(line: 9, column: 9, scope: !21)
!43 = !DILocation(line: 10, column: 14, scope: !10)
!44 = !DILocation(line: 10, column: 5, scope: !10)
!45 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 12, type: !12, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!46 = !DILocation(line: 12, column: 25, scope: !45)
!47 = !DILocation(line: 12, column: 18, scope: !45)
