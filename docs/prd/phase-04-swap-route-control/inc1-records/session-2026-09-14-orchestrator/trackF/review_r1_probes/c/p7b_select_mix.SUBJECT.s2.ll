; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p7b_select_mix.stage1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p7b_select_mix.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !23
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !23
    #dbg_value(i1 undef, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !24)
    #dbg_value(i8 0, !18, !DIExpression(), !24)
    #dbg_value(i8 0, !19, !DIExpression(), !24)
    #dbg_value(i32 5, !20, !DIExpression(), !24)
    #dbg_value(i32 2, !21, !DIExpression(), !24)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 0), !dbg !23
  call void @cqrt_x(i32 %h_cmp), !dbg !25
  %h1 = call i32 @cqrt_alloc_i1(i1 false), !dbg !26
  call void @cqrt_ry_i1_controlled(i32 %h_cmp, i32 %h1, double 5.000000e-01), !dbg !26
  call void @cqrt_x(i32 %h_cmp), !dbg !25
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 0), !dbg !23
  call void @cqrt_free(i32 %h_cmp), !dbg !25
    #dbg_value(i8 poison, !18, !DIExpression(), !24)
    #dbg_value(i32 2, !22, !DIExpression(), !24)
    #dbg_value(i8 0, !19, !DIExpression(), !24)
  %m = call i1 @cqrt_measure_i1(i32 %h1), !dbg !29
  %1 = zext i1 %m to i32, !dbg !29
  %2 = zext i1 false to i32, !dbg !30
  %3 = add nuw nsw i32 %2, %1, !dbg !31
  %4 = add nsw i32 %3, 2, !dbg !32
  ret i32 %4, !dbg !33
}

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i1(i32, double)

declare void @cqrt_ry_i1_controlled(i32, i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare i1 @cqrt_measure_i1(i32)

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p7b_select_mix.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "3009d5e84a7f5f4373c22827b4ff0ebc")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 4, type: !12, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p7b_select_mix.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "3009d5e84a7f5f4373c22827b4ff0ebc")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !18, !19, !20, !21, !22}
!16 = !DILocalVariable(name: "q", scope: !10, file: !11, line: 5, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 6, type: !17)
!19 = !DILocalVariable(name: "b2", scope: !10, file: !11, line: 6, type: !17)
!20 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 7, type: !14)
!21 = !DILocalVariable(name: "indep", scope: !10, file: !11, line: 7, type: !14)
!22 = !DILocalVariable(name: "mixed", scope: !10, file: !11, line: 9, type: !14)
!23 = !DILocation(line: 5, column: 14, scope: !10)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 8, column: 9, scope: !10)
!26 = !DILocation(line: 8, column: 19, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !11, line: 8, column: 12)
!28 = distinct !DILexicalBlock(scope: !10, file: !11, line: 8, column: 9)
!29 = !DILocation(line: 11, column: 12, scope: !10)
!30 = !DILocation(line: 11, column: 27, scope: !10)
!31 = !DILocation(line: 11, column: 26, scope: !10)
!32 = !DILocation(line: 11, column: 41, scope: !10)
!33 = !DILocation(line: 11, column: 5, scope: !10)
