; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.BaXOO1R2jM/s1.ll'
source_filename = "./w2c_noregion_inplace_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !18
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !18
    #dbg_value(i32 %h, !16, !DIExpression(), !19)
    #dbg_value(i32 0, !17, !DIExpression(), !19)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 3), !dbg !20
    #dbg_value(i32 %h_op, !16, !DIExpression(), !19)
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !22
    #dbg_value(i32 %m, !17, !DIExpression(), !19)
  %h_op1 = call i32 @cq_template_add_i32_hl(i32 %h, i32 6), !dbg !23
    #dbg_value(i32 %h_op1, !16, !DIExpression(), !19)
  %m2 = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !25
  %1 = add nsw i32 %m2, %m, !dbg !26
    #dbg_value(i32 %1, !17, !DIExpression(), !19)
  ret i32 %1, !dbg !27
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !28 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !29
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !29
    #dbg_value(i32 %h, !16, !DIExpression(), !31)
    #dbg_value(i32 0, !17, !DIExpression(), !31)
  %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 3), !dbg !32
    #dbg_value(i32 %h_op, !16, !DIExpression(), !31)
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !33
    #dbg_value(i32 %m, !17, !DIExpression(), !31)
  %h_op1 = call i32 @cq_template_add_i32_hl(i32 %h, i32 6), !dbg !34
    #dbg_value(i32 %h_op1, !16, !DIExpression(), !31)
  %m2 = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !35
  %1 = add nsw i32 %m2, %m, !dbg !36
    #dbg_value(i32 %1, !17, !DIExpression(), !31)
  ret i32 %1, !dbg !37
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

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
!8 = !DIFile(filename: "w2c_noregion_inplace_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "ddab5715f909615f606df73f12c72e3a")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !11, file: !11, line: 3, type: !12, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "./w2c_noregion_inplace_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "ddab5715f909615f606df73f12c72e3a")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17}
!16 = !DILocalVariable(name: "q", scope: !10, file: !11, line: 4, type: !14)
!17 = !DILocalVariable(name: "s", scope: !10, file: !11, line: 5, type: !14)
!18 = !DILocation(line: 4, column: 13, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 6, column: 13, scope: !21)
!21 = distinct !DILexicalBlock(scope: !10, file: !11, line: 6, column: 5)
!22 = !DILocation(line: 6, column: 23, scope: !21)
!23 = !DILocation(line: 7, column: 13, scope: !24)
!24 = distinct !DILexicalBlock(scope: !10, file: !11, line: 7, column: 5)
!25 = !DILocation(line: 7, column: 23, scope: !24)
!26 = !DILocation(line: 7, column: 20, scope: !24)
!27 = !DILocation(line: 8, column: 5, scope: !10)
!28 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 10, type: !12, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!29 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !30)
!30 = distinct !DILocation(line: 10, column: 25, scope: !28)
!31 = !DILocation(line: 0, scope: !10, inlinedAt: !30)
!32 = !DILocation(line: 6, column: 13, scope: !21, inlinedAt: !30)
!33 = !DILocation(line: 6, column: 23, scope: !21, inlinedAt: !30)
!34 = !DILocation(line: 7, column: 13, scope: !24, inlinedAt: !30)
!35 = !DILocation(line: 7, column: 23, scope: !24, inlinedAt: !30)
!36 = !DILocation(line: 7, column: 20, scope: !24, inlinedAt: !30)
!37 = !DILocation(line: 10, column: 18, scope: !28)
