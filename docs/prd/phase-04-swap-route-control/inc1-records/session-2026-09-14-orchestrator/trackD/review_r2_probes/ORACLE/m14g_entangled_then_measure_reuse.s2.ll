; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/m14g_entangled_then_measure_reuse.ll'
source_filename = "src/m14g_entangled_then_measure_reuse.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !19
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !19
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
  %h1 = call i32 @cqrt_alloc_i32(i32 0), !dbg !21
  call void @cqrt_ry_i32(i32 %h1, double 2.000000e-01), !dbg !21
    #dbg_value(i32 %h1, !16, !DIExpression(), !20)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 1), !dbg !22
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 0x3FE6666666666666), !dbg !24
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 1), !dbg !22
  call void @cqrt_free(i32 %h_cmp), !dbg !25
    #dbg_value(i32 %h1, !16, !DIExpression(), !20)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !26
    #dbg_value(i32 %m, !17, !DIExpression(), !20)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !27
    #dbg_value(i32 %h, !18, !DIExpression(), !20)
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !28
  %1 = add nsw i32 %m2, %m, !dbg !29
  %m3 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !30
  %2 = add nsw i32 %1, %m3, !dbg !31
  ret i32 %2, !dbg !32
}

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

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
!8 = !DIFile(filename: "src/m14g_entangled_then_measure_reuse.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "0e3286f729d7bc17c41fe2abb64a57f9")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "g", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "m", scope: !10, file: !8, line: 6, type: !13)
!18 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 6, type: !13)
!19 = !DILocation(line: 4, column: 23, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 4, column: 46, scope: !10)
!22 = !DILocation(line: 5, column: 7, scope: !23)
!23 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 6)
!24 = !DILocation(line: 5, column: 14, scope: !23)
!25 = !DILocation(line: 5, column: 6, scope: !10)
!26 = !DILocation(line: 6, column: 9, scope: !10)
!27 = !DILocation(line: 6, column: 30, scope: !10)
!28 = !DILocation(line: 6, column: 56, scope: !10)
!29 = !DILocation(line: 6, column: 55, scope: !10)
!30 = !DILocation(line: 6, column: 70, scope: !10)
!31 = !DILocation(line: 6, column: 69, scope: !10)
!32 = !DILocation(line: 6, column: 47, scope: !10)
