; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/out/w2h3_select_iterlocal_invread.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2h3_select_iterlocal_invread.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !26
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !26
    #dbg_value(i32 %h, !17, !DIExpression(), !27)
    #dbg_value(i32 0, !18, !DIExpression(), !27)
    #dbg_value(i32 0, !19, !DIExpression(), !28)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
  br label %3, !dbg !29

1:                                                ; preds = %3
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !30
  %2 = add nsw i32 %m, %8, !dbg !31
  ret i32 %2, !dbg !32

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %8, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %9, %3 ]
    #dbg_value(i32 %4, !18, !DIExpression(), !27)
    #dbg_value(i32 %5, !19, !DIExpression(), !28)
  %h2 = call i32 @cqrt_alloc_i32(i32 6), !dbg !33
  call void @cqrt_ry_i32(i32 %h2, double 4.000000e-01), !dbg !33
    #dbg_value(i32 %h2, !21, !DIExpression(), !34)
  %h3 = call i32 @cqrt_alloc_i1(i1 false), !dbg !35
  call void @cqrt_ry_i1(i32 %h3, double 5.000000e-01), !dbg !35
    #dbg_value(i32 %h3, !24, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !34)
  %bf = call i32 @cqrt_alloc_i1(i1 false), !dbg !36
  call void @cqrt_cnot(i32 %h3, i32 %bf), !dbg !36
  %out = call i32 @cqrt_alloc_i32(i32 0), !dbg !36
  %selop = call i32 @cqrt_alloc_i32(i32 2), !dbg !36
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out), !dbg !36
  call void @cqrt_x(i32 %bf), !dbg !36
  %selop1 = call i32 @cqrt_alloc_i32(i32 5), !dbg !36
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out), !dbg !36
  call void @cqrt_x(i32 %bf), !dbg !36
  call void @cqrt_cnot(i32 %h3, i32 %bf), !dbg !36
  call void @cqrt_free(i32 %bf), !dbg !36
    #dbg_value(i32 %out, !25, !DIExpression(), !34)
  %m6 = call i32 @cqrt_measure_i32(i32 %out), !dbg !37
  %h_op4 = call i32 @cq_template_lshr_i32_hl(i32 %h2, i32 1), !dbg !38
  %h_op5 = call i32 @cq_template_and_i32_hl(i32 %h_op4, i32 1), !dbg !38
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op4, i32 %h2, i32 1), !dbg !38
  call void @cqrt_free(i32 %h_op4), !dbg !38
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op5), !dbg !38
  %m8 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !39
  %6 = add i32 %m6, %4, !dbg !40
  %7 = add i32 %6, %m7, !dbg !41
  %8 = add i32 %7, %m8, !dbg !42
    #dbg_value(i32 %8, !18, !DIExpression(), !27)
  %9 = add nuw nsw i32 %5, 1, !dbg !43
    #dbg_value(i32 %9, !19, !DIExpression(), !28)
  %10 = icmp eq i32 %5, 0, !dbg !44
  br i1 %10, label %3, label %1, !dbg !29, !llvm.loop !45
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !49 {
  %1 = tail call i32 @slice(), !dbg !50
  ret i32 %1, !dbg !51
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!11}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2h3_select_iterlocal_invread.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "8d5bb3b2c162a7bb479b626e2b78950e")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 5, type: !13, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19, !21, !24, !25}
!17 = !DILocalVariable(name: "y", scope: !12, file: !8, line: 6, type: !15)
!18 = !DILocalVariable(name: "s", scope: !12, file: !8, line: 7, type: !15)
!19 = !DILocalVariable(name: "k", scope: !20, file: !8, line: 8, type: !15)
!20 = distinct !DILexicalBlock(scope: !12, file: !8, line: 8, column: 5)
!21 = !DILocalVariable(name: "u", scope: !22, file: !8, line: 9, type: !15)
!22 = distinct !DILexicalBlock(scope: !23, file: !8, line: 8, column: 33)
!23 = distinct !DILexicalBlock(scope: !20, file: !8, line: 8, column: 5)
!24 = !DILocalVariable(name: "b", scope: !22, file: !8, line: 10, type: !10)
!25 = !DILocalVariable(name: "a", scope: !22, file: !8, line: 11, type: !15)
!26 = !DILocation(line: 6, column: 13, scope: !12)
!27 = !DILocation(line: 0, scope: !12)
!28 = !DILocation(line: 0, scope: !20)
!29 = !DILocation(line: 8, column: 5, scope: !20)
!30 = !DILocation(line: 14, column: 16, scope: !12)
!31 = !DILocation(line: 14, column: 14, scope: !12)
!32 = !DILocation(line: 14, column: 5, scope: !12)
!33 = !DILocation(line: 9, column: 18, scope: !22)
!34 = !DILocation(line: 0, scope: !22)
!35 = !DILocation(line: 10, column: 18, scope: !22)
!36 = !DILocation(line: 11, column: 18, scope: !22)
!37 = !DILocation(line: 12, column: 14, scope: !22)
!38 = !DILocation(line: 12, column: 30, scope: !22)
!39 = !DILocation(line: 12, column: 57, scope: !22)
!40 = !DILocation(line: 12, column: 28, scope: !22)
!41 = !DILocation(line: 12, column: 55, scope: !22)
!42 = !DILocation(line: 12, column: 11, scope: !22)
!43 = !DILocation(line: 8, column: 28, scope: !23)
!44 = !DILocation(line: 8, column: 23, scope: !23)
!45 = distinct !{!45, !29, !46, !47, !48}
!46 = !DILocation(line: 13, column: 5, scope: !20)
!47 = !{!"llvm.loop.mustprogress"}
!48 = !{!"llvm.loop.unroll.disable"}
!49 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 16, type: !13, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!50 = !DILocation(line: 16, column: 25, scope: !49)
!51 = !DILocation(line: 16, column: 18, scope: !49)
