; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/a2_fanout_body_rail_un.ora.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a2_fanout_body_rail_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !21
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !21
    #dbg_value(i32 %h, !15, !DIExpression(), !22)
    #dbg_value(i32 0, !16, !DIExpression(), !22)
  %h_op = call i32 @cq_template_ashr_i32_hl(i32 %h, i32 1), !dbg !23
    #dbg_value(i32 %h_op, !17, !DIExpression(), !24)
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !25
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !25
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 2), !dbg !26
  call void @cq_template_ashr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !23
  call void @cqrt_free(i32 %h_op), !dbg !23
  %m6 = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !26
    #dbg_value(i32 poison, !16, !DIExpression(), !22)
  %h_op3 = call i32 @cq_template_ashr_i32_hl(i32 %h, i32 2), !dbg !27
    #dbg_value(i32 %h_op3, !19, !DIExpression(), !28)
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h_op3, i32 1), !dbg !29
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !29
  %h_op5 = call i32 @cq_template_and_i32_hl(i32 %h_op3, i32 2), !dbg !30
  call void @cq_template_ashr_i32_hl_unc(i32 %h_op3, i32 %h, i32 2), !dbg !27
  call void @cqrt_free(i32 %h_op3), !dbg !27
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op5), !dbg !30
    #dbg_value(i32 %3, !16, !DIExpression(), !22)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !31
    #dbg_value(i32 %h, !15, !DIExpression(), !22)
  %m9 = call i32 @cqrt_measure_i32(i32 %h), !dbg !32
  %1 = add i32 %m6, %m, !dbg !33
  %2 = add i32 %1, %m7, !dbg !34
  %3 = add i32 %2, %m8, !dbg !35
  %4 = add nsw i32 %3, %m9, !dbg !36
  ret i32 %4, !dbg !37
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !38 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !39
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !39
    #dbg_value(i32 %h, !15, !DIExpression(), !41)
    #dbg_value(i32 0, !16, !DIExpression(), !41)
  %h_op = call i32 @cq_template_ashr_i32_hl(i32 %h, i32 1), !dbg !42
    #dbg_value(i32 %h_op, !17, !DIExpression(), !43)
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !44
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !44
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 2), !dbg !45
  call void @cq_template_ashr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !42
  call void @cqrt_free(i32 %h_op), !dbg !42
  %m6 = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !45
    #dbg_value(i32 poison, !16, !DIExpression(), !41)
  %h_op3 = call i32 @cq_template_ashr_i32_hl(i32 %h, i32 2), !dbg !46
    #dbg_value(i32 %h_op3, !19, !DIExpression(), !47)
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h_op3, i32 1), !dbg !48
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !48
  %h_op5 = call i32 @cq_template_and_i32_hl(i32 %h_op3, i32 2), !dbg !49
  call void @cq_template_ashr_i32_hl_unc(i32 %h_op3, i32 %h, i32 2), !dbg !46
  call void @cqrt_free(i32 %h_op3), !dbg !46
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op5), !dbg !49
    #dbg_value(i32 %3, !16, !DIExpression(), !41)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !50
    #dbg_value(i32 %h, !15, !DIExpression(), !41)
  %m9 = call i32 @cqrt_measure_i32(i32 %h), !dbg !51
  %1 = add i32 %m6, %m, !dbg !52
  %2 = add i32 %1, %m7, !dbg !53
  %3 = add i32 %2, %m8, !dbg !54
  %4 = add nsw i32 %3, %m9, !dbg !55
  ret i32 %4, !dbg !56
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_ashr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_ashr_i32_hl_unc(i32, i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a2_fanout_body_rail_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "9981ec91e5b3f31e7616850efbe085d2")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "t", scope: !18, file: !8, line: 5, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 5)
!19 = !DILocalVariable(name: "t", scope: !20, file: !8, line: 6, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 5)
!21 = !DILocation(line: 3, column: 13, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 5, column: 17, scope: !18)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 5, column: 28, scope: !18)
!26 = !DILocation(line: 5, column: 48, scope: !18)
!27 = !DILocation(line: 6, column: 17, scope: !20)
!28 = !DILocation(line: 0, scope: !20)
!29 = !DILocation(line: 6, column: 28, scope: !20)
!30 = !DILocation(line: 6, column: 48, scope: !20)
!31 = !DILocation(line: 7, column: 9, scope: !10)
!32 = !DILocation(line: 8, column: 16, scope: !10)
!33 = !DILocation(line: 6, column: 46, scope: !20)
!34 = !DILocation(line: 5, column: 46, scope: !18)
!35 = !DILocation(line: 6, column: 25, scope: !20)
!36 = !DILocation(line: 8, column: 14, scope: !10)
!37 = !DILocation(line: 8, column: 5, scope: !10)
!38 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!39 = !DILocation(line: 3, column: 13, scope: !10, inlinedAt: !40)
!40 = distinct !DILocation(line: 10, column: 25, scope: !38)
!41 = !DILocation(line: 0, scope: !10, inlinedAt: !40)
!42 = !DILocation(line: 5, column: 17, scope: !18, inlinedAt: !40)
!43 = !DILocation(line: 0, scope: !18, inlinedAt: !40)
!44 = !DILocation(line: 5, column: 28, scope: !18, inlinedAt: !40)
!45 = !DILocation(line: 5, column: 48, scope: !18, inlinedAt: !40)
!46 = !DILocation(line: 6, column: 17, scope: !20, inlinedAt: !40)
!47 = !DILocation(line: 0, scope: !20, inlinedAt: !40)
!48 = !DILocation(line: 6, column: 28, scope: !20, inlinedAt: !40)
!49 = !DILocation(line: 6, column: 48, scope: !20, inlinedAt: !40)
!50 = !DILocation(line: 7, column: 9, scope: !10, inlinedAt: !40)
!51 = !DILocation(line: 8, column: 16, scope: !10, inlinedAt: !40)
!52 = !DILocation(line: 6, column: 46, scope: !20, inlinedAt: !40)
!53 = !DILocation(line: 5, column: 46, scope: !18, inlinedAt: !40)
!54 = !DILocation(line: 6, column: 25, scope: !20, inlinedAt: !40)
!55 = !DILocation(line: 8, column: 14, scope: !10, inlinedAt: !40)
!56 = !DILocation(line: 10, column: 18, scope: !38)
