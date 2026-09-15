; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/r2_two_functions_un.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r2_two_functions_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ka() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !17
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !17
    #dbg_value(i32 %h, !15, !DIExpression(), !18)
    #dbg_value(i32 0, !16, !DIExpression(), !18)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !19
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !19
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !19
  call void @cqrt_free(i32 %h_op), !dbg !19
  %m = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !19
    #dbg_value(i32 %m, !16, !DIExpression(), !18)
  %h_op2 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 2), !dbg !20
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op2, i32 1), !dbg !20
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op2, i32 %h, i32 2), !dbg !20
  call void @cqrt_free(i32 %h_op2), !dbg !20
  %m4 = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !20
  %1 = add nsw i32 %m4, %m, !dbg !21
    #dbg_value(i32 %1, !16, !DIExpression(), !18)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !22
    #dbg_value(i32 %h, !15, !DIExpression(), !18)
  %m5 = call i32 @cqrt_measure_i32(i32 %h), !dbg !23
  %2 = add nsw i32 %1, %m5, !dbg !24
  ret i32 %2, !dbg !25
}

; Function Attrs: nounwind ssp uwtable
define i32 @kb() local_unnamed_addr #0 !dbg !26 {
  %h = call i32 @cqrt_alloc_i32(i32 6), !dbg !31
  call void @cqrt_ry_i32(i32 %h, double 4.000000e-01), !dbg !31
    #dbg_value(i32 %h, !28, !DIExpression(), !32)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3), !dbg !33
    #dbg_value(i32 %h_op, !29, !DIExpression(), !32)
    #dbg_value(i32 0, !30, !DIExpression(), !32)
  %h_op1 = call i32 @cq_template_lshr_i32_hl(i32 %h_op, i32 1), !dbg !34
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op1, i32 1), !dbg !34
  %m = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !34
    #dbg_value(i32 %m, !30, !DIExpression(), !32)
  %h_op3 = call i32 @cq_template_lshr_i32_hl(i32 %h_op, i32 2), !dbg !35
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h_op3, i32 1), !dbg !35
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op3, i32 %h_op, i32 2), !dbg !35
  call void @cqrt_free(i32 %h_op3), !dbg !35
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op1, i32 %h_op, i32 1), !dbg !34
  call void @cqrt_free(i32 %h_op1), !dbg !34
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3), !dbg !33
  call void @cqrt_free(i32 %h_op), !dbg !33
  %m5 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !35
  %1 = add nsw i32 %m5, %m, !dbg !36
    #dbg_value(i32 %1, !30, !DIExpression(), !32)
  %m6 = call i32 @cqrt_measure_i32(i32 %h), !dbg !37
  %2 = add nsw i32 %1, %m6, !dbg !38
  ret i32 %2, !dbg !39
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !40 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !41
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !41
    #dbg_value(i32 %h, !15, !DIExpression(), !43)
    #dbg_value(i32 0, !16, !DIExpression(), !43)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !44
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !44
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !44
  call void @cqrt_free(i32 %h_op), !dbg !44
  %m = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !44
    #dbg_value(i32 %m, !16, !DIExpression(), !43)
  %h_op3 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 2), !dbg !45
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h_op3, i32 1), !dbg !45
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op3, i32 %h, i32 2), !dbg !45
  call void @cqrt_free(i32 %h_op3), !dbg !45
  %m10 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !45
    #dbg_value(i32 poison, !16, !DIExpression(), !43)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !46
    #dbg_value(i32 %h, !15, !DIExpression(), !43)
  %m11 = call i32 @cqrt_measure_i32(i32 %h), !dbg !47
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !48
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !48
    #dbg_value(i32 %h1, !28, !DIExpression(), !50)
  %h_op5 = call i32 @cq_template_mul_i32_hl(i32 %h1, i32 3), !dbg !51
    #dbg_value(i32 %h_op5, !29, !DIExpression(), !50)
    #dbg_value(i32 0, !30, !DIExpression(), !50)
  %h_op6 = call i32 @cq_template_lshr_i32_hl(i32 %h_op5, i32 1), !dbg !52
  %h_op7 = call i32 @cq_template_and_i32_hl(i32 %h_op6, i32 1), !dbg !52
  %m12 = call i32 @cqrt_measure_i32(i32 %h_op7), !dbg !52
    #dbg_value(i32 %m12, !30, !DIExpression(), !50)
  %h_op8 = call i32 @cq_template_lshr_i32_hl(i32 %h_op5, i32 2), !dbg !53
  %h_op9 = call i32 @cq_template_and_i32_hl(i32 %h_op8, i32 1), !dbg !53
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op8, i32 %h_op5, i32 2), !dbg !53
  call void @cqrt_free(i32 %h_op8), !dbg !53
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op6, i32 %h_op5, i32 1), !dbg !52
  call void @cqrt_free(i32 %h_op6), !dbg !52
  call void @cq_template_mul_i32_hl_unc(i32 %h_op5, i32 %h1, i32 3), !dbg !51
  call void @cqrt_free(i32 %h_op5), !dbg !51
  %m13 = call i32 @cqrt_measure_i32(i32 %h_op9), !dbg !53
    #dbg_value(i32 poison, !30, !DIExpression(), !50)
  %m14 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !54
  %1 = add i32 %m10, %m, !dbg !55
  %2 = add i32 %1, %m11, !dbg !56
  %3 = add i32 %2, %m12, !dbg !57
  %4 = add i32 %3, %m13, !dbg !58
  %5 = add i32 %4, %m14, !dbg !59
  ret i32 %5, !dbg !60
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r2_two_functions_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "d1c54e24225a17591605197027f8a4b0")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "ka", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocation(line: 3, column: 13, scope: !10)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 5, column: 10, scope: !10)
!20 = !DILocation(line: 6, column: 10, scope: !10)
!21 = !DILocation(line: 6, column: 7, scope: !10)
!22 = !DILocation(line: 7, column: 9, scope: !10)
!23 = !DILocation(line: 8, column: 16, scope: !10)
!24 = !DILocation(line: 8, column: 14, scope: !10)
!25 = !DILocation(line: 8, column: 5, scope: !10)
!26 = distinct !DISubprogram(name: "kb", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !27)
!27 = !{!28, !29, !30}
!28 = !DILocalVariable(name: "y", scope: !26, file: !8, line: 11, type: !13)
!29 = !DILocalVariable(name: "p", scope: !26, file: !8, line: 12, type: !13)
!30 = !DILocalVariable(name: "s", scope: !26, file: !8, line: 13, type: !13)
!31 = !DILocation(line: 11, column: 13, scope: !26)
!32 = !DILocation(line: 0, scope: !26)
!33 = !DILocation(line: 12, column: 15, scope: !26)
!34 = !DILocation(line: 14, column: 10, scope: !26)
!35 = !DILocation(line: 15, column: 10, scope: !26)
!36 = !DILocation(line: 15, column: 7, scope: !26)
!37 = !DILocation(line: 16, column: 16, scope: !26)
!38 = !DILocation(line: 16, column: 14, scope: !26)
!39 = !DILocation(line: 16, column: 5, scope: !26)
!40 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 18, type: !11, scopeLine: 18, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!41 = !DILocation(line: 3, column: 13, scope: !10, inlinedAt: !42)
!42 = distinct !DILocation(line: 18, column: 25, scope: !40)
!43 = !DILocation(line: 0, scope: !10, inlinedAt: !42)
!44 = !DILocation(line: 5, column: 10, scope: !10, inlinedAt: !42)
!45 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !42)
!46 = !DILocation(line: 7, column: 9, scope: !10, inlinedAt: !42)
!47 = !DILocation(line: 8, column: 16, scope: !10, inlinedAt: !42)
!48 = !DILocation(line: 11, column: 13, scope: !26, inlinedAt: !49)
!49 = distinct !DILocation(line: 18, column: 32, scope: !40)
!50 = !DILocation(line: 0, scope: !26, inlinedAt: !49)
!51 = !DILocation(line: 12, column: 15, scope: !26, inlinedAt: !49)
!52 = !DILocation(line: 14, column: 10, scope: !26, inlinedAt: !49)
!53 = !DILocation(line: 15, column: 10, scope: !26, inlinedAt: !49)
!54 = !DILocation(line: 16, column: 16, scope: !26, inlinedAt: !49)
!55 = !DILocation(line: 15, column: 7, scope: !26, inlinedAt: !49)
!56 = !DILocation(line: 16, column: 14, scope: !26, inlinedAt: !49)
!57 = !DILocation(line: 6, column: 7, scope: !10, inlinedAt: !42)
!58 = !DILocation(line: 8, column: 14, scope: !10, inlinedAt: !42)
!59 = !DILocation(line: 18, column: 30, scope: !40)
!60 = !DILocation(line: 18, column: 18, scope: !40)
