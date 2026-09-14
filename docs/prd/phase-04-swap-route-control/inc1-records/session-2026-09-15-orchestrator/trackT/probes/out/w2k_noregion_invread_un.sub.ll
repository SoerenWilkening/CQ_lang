; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/out/w2k_noregion_invread_un.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2k_noregion_invread_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !21
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !21
    #dbg_value(i32 %h, !15, !DIExpression(), !22)
    #dbg_value(i32 0, !16, !DIExpression(), !22)
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !23
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !23
    #dbg_value(i32 %h1, !17, !DIExpression(), !24)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h1, i32 1), !dbg !25
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !25
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h1, i32 1), !dbg !25
  call void @cqrt_free(i32 %h_op), !dbg !25
  %m = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !25
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !26
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !26
    #dbg_value(i32 poison, !16, !DIExpression(), !22)
  %h2 = call i32 @cqrt_alloc_i32(i32 6), !dbg !27
  call void @cqrt_ry_i32(i32 %h2, double 4.000000e-01), !dbg !27
    #dbg_value(i32 %h2, !19, !DIExpression(), !28)
  %h_op5 = call i32 @cq_template_lshr_i32_hl(i32 %h2, i32 1), !dbg !29
  %h_op6 = call i32 @cq_template_and_i32_hl(i32 %h_op5, i32 1), !dbg !29
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op5, i32 %h2, i32 1), !dbg !29
  call void @cqrt_free(i32 %h_op5), !dbg !29
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op6), !dbg !29
  %m9 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !30
    #dbg_value(i32 %3, !16, !DIExpression(), !22)
  %m10 = call i32 @cqrt_measure_i32(i32 %h), !dbg !31
  %1 = add i32 %m7, %m, !dbg !32
  %2 = add i32 %1, %m8, !dbg !33
  %3 = add i32 %2, %m9, !dbg !34
  %4 = add nsw i32 %3, %m10, !dbg !35
  ret i32 %4, !dbg !36
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !37 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !38
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !38
    #dbg_value(i32 %h, !15, !DIExpression(), !40)
    #dbg_value(i32 0, !16, !DIExpression(), !40)
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !41
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !41
    #dbg_value(i32 %h1, !17, !DIExpression(), !42)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h1, i32 1), !dbg !43
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !43
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h1, i32 1), !dbg !43
  call void @cqrt_free(i32 %h_op), !dbg !43
  %m = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !43
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !44
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !44
    #dbg_value(i32 poison, !16, !DIExpression(), !40)
  %h2 = call i32 @cqrt_alloc_i32(i32 6), !dbg !45
  call void @cqrt_ry_i32(i32 %h2, double 4.000000e-01), !dbg !45
    #dbg_value(i32 %h2, !19, !DIExpression(), !46)
  %h_op5 = call i32 @cq_template_lshr_i32_hl(i32 %h2, i32 1), !dbg !47
  %h_op6 = call i32 @cq_template_and_i32_hl(i32 %h_op5, i32 1), !dbg !47
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op5, i32 %h2, i32 1), !dbg !47
  call void @cqrt_free(i32 %h_op5), !dbg !47
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op6), !dbg !47
  %m9 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !48
    #dbg_value(i32 %3, !16, !DIExpression(), !40)
  %m10 = call i32 @cqrt_measure_i32(i32 %h), !dbg !49
  %1 = add i32 %m7, %m, !dbg !50
  %2 = add i32 %1, %m8, !dbg !51
  %3 = add i32 %2, %m9, !dbg !52
  %4 = add nsw i32 %3, %m10, !dbg !53
  ret i32 %4, !dbg !54
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2k_noregion_invread_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "6db310d92c366970cecf56763bded134")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocalVariable(name: "u", scope: !18, file: !8, line: 6, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 5)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 7, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 7, column: 5)
!21 = !DILocation(line: 4, column: 13, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 6, column: 15, scope: !18)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 6, column: 38, scope: !18)
!26 = !DILocation(line: 6, column: 65, scope: !18)
!27 = !DILocation(line: 7, column: 15, scope: !20)
!28 = !DILocation(line: 0, scope: !20)
!29 = !DILocation(line: 7, column: 38, scope: !20)
!30 = !DILocation(line: 7, column: 65, scope: !20)
!31 = !DILocation(line: 8, column: 16, scope: !10)
!32 = !DILocation(line: 7, column: 63, scope: !20)
!33 = !DILocation(line: 6, column: 63, scope: !18)
!34 = !DILocation(line: 7, column: 35, scope: !20)
!35 = !DILocation(line: 8, column: 14, scope: !10)
!36 = !DILocation(line: 8, column: 5, scope: !10)
!37 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!38 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !39)
!39 = distinct !DILocation(line: 10, column: 25, scope: !37)
!40 = !DILocation(line: 0, scope: !10, inlinedAt: !39)
!41 = !DILocation(line: 6, column: 15, scope: !18, inlinedAt: !39)
!42 = !DILocation(line: 0, scope: !18, inlinedAt: !39)
!43 = !DILocation(line: 6, column: 38, scope: !18, inlinedAt: !39)
!44 = !DILocation(line: 6, column: 65, scope: !18, inlinedAt: !39)
!45 = !DILocation(line: 7, column: 15, scope: !20, inlinedAt: !39)
!46 = !DILocation(line: 0, scope: !20, inlinedAt: !39)
!47 = !DILocation(line: 7, column: 38, scope: !20, inlinedAt: !39)
!48 = !DILocation(line: 7, column: 65, scope: !20, inlinedAt: !39)
!49 = !DILocation(line: 8, column: 16, scope: !10, inlinedAt: !39)
!50 = !DILocation(line: 7, column: 63, scope: !20, inlinedAt: !39)
!51 = !DILocation(line: 6, column: 63, scope: !18, inlinedAt: !39)
!52 = !DILocation(line: 7, column: 35, scope: !20, inlinedAt: !39)
!53 = !DILocation(line: 8, column: 14, scope: !10, inlinedAt: !39)
!54 = !DILocation(line: 10, column: 18, scope: !37)
