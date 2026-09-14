; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.JP3wBrIurT/s1.ll'
source_filename = "./ctl_wj_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !16, !DIExpression(), !23)
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !24
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !24
    #dbg_value(i32 %h, !17, !DIExpression(), !25)
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !26
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01), !dbg !26
    #dbg_value(i32 %h2, !19, !DIExpression(), !25)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 2), !dbg !27
  %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !27
  call void @cqrt_x(i32 %h_cmp1), !dbg !29
  call void @cqrt_ry_i32_controlled(i32 %h_cmp1, i32 %h2, double 2.000000e-01), !dbg !30
  call void @cqrt_x(i32 %h_cmp1), !dbg !29
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp1, i32 %h_op, i32 0), !dbg !27
  call void @cq_template_and_i32_hl_unc(i32 %h_op, i32 %h, i32 2), !dbg !27
  call void @cqrt_free(i32 %h_op), !dbg !27
  call void @cqrt_free(i32 %h_cmp1), !dbg !29
    #dbg_value(i32 %h2, !19, !DIExpression(), !25)
  %m = call i32 @cqrt_measure_i32(i32 %h2), !dbg !31
  %m6 = call i32 @cqrt_measure_i32(i32 %h), !dbg !32
    #dbg_value(!DIArgList(i32 %m, i32 %m6), !16, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !23)
  %h3 = call i32 @cqrt_alloc_i32(i32 5), !dbg !33
  call void @cqrt_ry_i32(i32 %h3, double 5.000000e-01), !dbg !33
    #dbg_value(i32 %h3, !20, !DIExpression(), !34)
  %h4 = call i32 @cqrt_alloc_i32(i32 7), !dbg !35
  call void @cqrt_ry_i32(i32 %h4, double 2.500000e-01), !dbg !35
    #dbg_value(i32 %h4, !22, !DIExpression(), !34)
  %h_op5 = call i32 @cq_template_and_i32_hl(i32 %h3, i32 2), !dbg !36
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op5, i32 0), !dbg !36
  call void @cqrt_x(i32 %h_cmp), !dbg !38
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h4, double 2.000000e-01), !dbg !39
  call void @cqrt_x(i32 %h_cmp), !dbg !38
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op5, i32 0), !dbg !36
  call void @cq_template_and_i32_hl_unc(i32 %h_op5, i32 %h3, i32 2), !dbg !36
  call void @cqrt_free(i32 %h_op5), !dbg !36
  call void @cqrt_free(i32 %h_cmp), !dbg !38
    #dbg_value(i32 poison, !16, !DIExpression(), !23)
    #dbg_value(i32 %h4, !22, !DIExpression(), !34)
  %m7 = call i32 @cqrt_measure_i32(i32 %h4), !dbg !40
  %m8 = call i32 @cqrt_measure_i32(i32 %h3), !dbg !41
  %1 = add i32 %m6, %m, !dbg !42
  %2 = add i32 %1, %m7, !dbg !43
  %3 = add i32 %2, %m8, !dbg !44
    #dbg_value(i32 %3, !16, !DIExpression(), !23)
  ret i32 %3, !dbg !45
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !46 {
  %1 = tail call i32 @slice(), !dbg !47
  ret i32 %1, !dbg !48
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
!8 = !DIFile(filename: "ctl_wj_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "a9287ebd9f36bbee523eb4f60f1071d0")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !11, file: !11, line: 2, type: !12, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "./ctl_wj_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "a9287ebd9f36bbee523eb4f60f1071d0")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !19, !20, !22}
!16 = !DILocalVariable(name: "s", scope: !10, file: !11, line: 3, type: !14)
!17 = !DILocalVariable(name: "u", scope: !18, file: !11, line: 4, type: !14)
!18 = distinct !DILexicalBlock(scope: !10, file: !11, line: 4, column: 5)
!19 = !DILocalVariable(name: "r", scope: !18, file: !11, line: 4, type: !14)
!20 = !DILocalVariable(name: "u", scope: !21, file: !11, line: 5, type: !14)
!21 = distinct !DILexicalBlock(scope: !10, file: !11, line: 5, column: 5)
!22 = !DILocalVariable(name: "r", scope: !21, file: !11, line: 5, type: !14)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 4, column: 15, scope: !18)
!25 = !DILocation(line: 0, scope: !18)
!26 = !DILocation(line: 4, column: 41, scope: !18)
!27 = !DILocation(line: 4, column: 73, scope: !28)
!28 = distinct !DILexicalBlock(scope: !18, file: !11, line: 4, column: 64)
!29 = !DILocation(line: 4, column: 64, scope: !18)
!30 = !DILocation(line: 4, column: 82, scope: !28)
!31 = !DILocation(line: 4, column: 105, scope: !18)
!32 = !DILocation(line: 4, column: 121, scope: !18)
!33 = !DILocation(line: 5, column: 15, scope: !21)
!34 = !DILocation(line: 0, scope: !21)
!35 = !DILocation(line: 5, column: 41, scope: !21)
!36 = !DILocation(line: 5, column: 73, scope: !37)
!37 = distinct !DILexicalBlock(scope: !21, file: !11, line: 5, column: 64)
!38 = !DILocation(line: 5, column: 64, scope: !21)
!39 = !DILocation(line: 5, column: 82, scope: !37)
!40 = !DILocation(line: 5, column: 105, scope: !21)
!41 = !DILocation(line: 5, column: 121, scope: !21)
!42 = !DILocation(line: 5, column: 119, scope: !21)
!43 = !DILocation(line: 4, column: 119, scope: !18)
!44 = !DILocation(line: 5, column: 102, scope: !21)
!45 = !DILocation(line: 6, column: 5, scope: !10)
!46 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 8, type: !12, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!47 = !DILocation(line: 8, column: 25, scope: !46)
!48 = !DILocation(line: 8, column: 18, scope: !46)
