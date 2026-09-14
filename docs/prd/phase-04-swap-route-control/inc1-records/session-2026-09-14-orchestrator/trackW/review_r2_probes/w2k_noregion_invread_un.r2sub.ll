; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.E1QvwYRz4V/s1.ll'
source_filename = "./w2k_noregion_invread_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !22
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !22
    #dbg_value(i32 %h, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !23)
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !24
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !24
    #dbg_value(i32 %h1, !18, !DIExpression(), !25)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h1, i32 1), !dbg !26
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !26
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h1, i32 1), !dbg !26
  call void @cqrt_free(i32 %h_op), !dbg !26
  %m = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !26
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !27
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !27
    #dbg_value(i32 poison, !17, !DIExpression(), !23)
  %h2 = call i32 @cqrt_alloc_i32(i32 6), !dbg !28
  call void @cqrt_ry_i32(i32 %h2, double 4.000000e-01), !dbg !28
    #dbg_value(i32 %h2, !20, !DIExpression(), !29)
  %h_op5 = call i32 @cq_template_lshr_i32_hl(i32 %h2, i32 1), !dbg !30
  %h_op6 = call i32 @cq_template_and_i32_hl(i32 %h_op5, i32 1), !dbg !30
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op5, i32 %h2, i32 1), !dbg !30
  call void @cqrt_free(i32 %h_op5), !dbg !30
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op6), !dbg !30
  %m9 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !31
    #dbg_value(i32 %3, !17, !DIExpression(), !23)
  %m10 = call i32 @cqrt_measure_i32(i32 %h), !dbg !32
  %1 = add i32 %m7, %m, !dbg !33
  %2 = add i32 %1, %m8, !dbg !34
  %3 = add i32 %2, %m9, !dbg !35
  %4 = add nsw i32 %3, %m10, !dbg !36
  ret i32 %4, !dbg !37
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !38 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !39
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !39
    #dbg_value(i32 %h, !16, !DIExpression(), !41)
    #dbg_value(i32 0, !17, !DIExpression(), !41)
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !42
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !42
    #dbg_value(i32 %h1, !18, !DIExpression(), !43)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h1, i32 1), !dbg !44
  %h_op3 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !44
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h1, i32 1), !dbg !44
  call void @cqrt_free(i32 %h_op), !dbg !44
  %m = call i32 @cqrt_measure_i32(i32 %h_op3), !dbg !44
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h, i32 1), !dbg !45
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !45
    #dbg_value(i32 poison, !17, !DIExpression(), !41)
  %h2 = call i32 @cqrt_alloc_i32(i32 6), !dbg !46
  call void @cqrt_ry_i32(i32 %h2, double 4.000000e-01), !dbg !46
    #dbg_value(i32 %h2, !20, !DIExpression(), !47)
  %h_op5 = call i32 @cq_template_lshr_i32_hl(i32 %h2, i32 1), !dbg !48
  %h_op6 = call i32 @cq_template_and_i32_hl(i32 %h_op5, i32 1), !dbg !48
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op5, i32 %h2, i32 1), !dbg !48
  call void @cqrt_free(i32 %h_op5), !dbg !48
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op6), !dbg !48
  %m9 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !49
    #dbg_value(i32 %3, !17, !DIExpression(), !41)
  %m10 = call i32 @cqrt_measure_i32(i32 %h), !dbg !50
  %1 = add i32 %m7, %m, !dbg !51
  %2 = add i32 %1, %m8, !dbg !52
  %3 = add i32 %2, %m9, !dbg !53
  %4 = add nsw i32 %3, %m10, !dbg !54
  ret i32 %4, !dbg !55
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
!8 = !DIFile(filename: "w2k_noregion_invread_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "6db310d92c366970cecf56763bded134")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !11, file: !11, line: 3, type: !12, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "./w2k_noregion_invread_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "6db310d92c366970cecf56763bded134")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18, !20}
!16 = !DILocalVariable(name: "y", scope: !10, file: !11, line: 4, type: !14)
!17 = !DILocalVariable(name: "s", scope: !10, file: !11, line: 5, type: !14)
!18 = !DILocalVariable(name: "u", scope: !19, file: !11, line: 6, type: !14)
!19 = distinct !DILexicalBlock(scope: !10, file: !11, line: 6, column: 5)
!20 = !DILocalVariable(name: "u", scope: !21, file: !11, line: 7, type: !14)
!21 = distinct !DILexicalBlock(scope: !10, file: !11, line: 7, column: 5)
!22 = !DILocation(line: 4, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 6, column: 15, scope: !19)
!25 = !DILocation(line: 0, scope: !19)
!26 = !DILocation(line: 6, column: 38, scope: !19)
!27 = !DILocation(line: 6, column: 65, scope: !19)
!28 = !DILocation(line: 7, column: 15, scope: !21)
!29 = !DILocation(line: 0, scope: !21)
!30 = !DILocation(line: 7, column: 38, scope: !21)
!31 = !DILocation(line: 7, column: 65, scope: !21)
!32 = !DILocation(line: 8, column: 16, scope: !10)
!33 = !DILocation(line: 7, column: 63, scope: !21)
!34 = !DILocation(line: 6, column: 63, scope: !19)
!35 = !DILocation(line: 7, column: 35, scope: !21)
!36 = !DILocation(line: 8, column: 14, scope: !10)
!37 = !DILocation(line: 8, column: 5, scope: !10)
!38 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 10, type: !12, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!39 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !40)
!40 = distinct !DILocation(line: 10, column: 25, scope: !38)
!41 = !DILocation(line: 0, scope: !10, inlinedAt: !40)
!42 = !DILocation(line: 6, column: 15, scope: !19, inlinedAt: !40)
!43 = !DILocation(line: 0, scope: !19, inlinedAt: !40)
!44 = !DILocation(line: 6, column: 38, scope: !19, inlinedAt: !40)
!45 = !DILocation(line: 6, column: 65, scope: !19, inlinedAt: !40)
!46 = !DILocation(line: 7, column: 15, scope: !21, inlinedAt: !40)
!47 = !DILocation(line: 0, scope: !21, inlinedAt: !40)
!48 = !DILocation(line: 7, column: 38, scope: !21, inlinedAt: !40)
!49 = !DILocation(line: 7, column: 65, scope: !21, inlinedAt: !40)
!50 = !DILocation(line: 8, column: 16, scope: !10, inlinedAt: !40)
!51 = !DILocation(line: 7, column: 63, scope: !21, inlinedAt: !40)
!52 = !DILocation(line: 6, column: 63, scope: !19, inlinedAt: !40)
!53 = !DILocation(line: 7, column: 35, scope: !21, inlinedAt: !40)
!54 = !DILocation(line: 8, column: 14, scope: !10, inlinedAt: !40)
!55 = !DILocation(line: 10, column: 18, scope: !38)
