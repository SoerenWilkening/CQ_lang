; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.HdS9U98wbg/s1.ll'
source_filename = "./w2h_phase_inloop_invread.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !23
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !23
    #dbg_value(i32 %h, !16, !DIExpression(), !24)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
    #dbg_value(i32 0, !18, !DIExpression(), !25)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
  br label %3, !dbg !26

1:                                                ; preds = %3
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !27
  %2 = add nsw i32 %m, %7, !dbg !28
  ret i32 %2, !dbg !29

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %8, %3 ]
    #dbg_value(i32 %4, !17, !DIExpression(), !24)
    #dbg_value(i32 %5, !18, !DIExpression(), !25)
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !30
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !30
    #dbg_value(i32 %h1, !20, !DIExpression(), !31)
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h1, i32 2), !dbg !32
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op2, i32 0), !dbg !32
  call void @cqrt_x(i32 %h_cmp), !dbg !34
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01), !dbg !34, !cq.branchphase !35
  call void @cqrt_x(i32 %h_cmp), !dbg !34
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op2, i32 0), !dbg !32
  call void @cqrt_free(i32 %h_cmp), !dbg !34
  %h_op3 = call i32 @cq_template_lshr_i32_hl(i32 %h1, i32 2), !dbg !36
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h_op3, i32 1), !dbg !36
  %m5 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !36
  %m6 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !37
  %6 = add i32 %m5, %4, !dbg !38
  %7 = add i32 %6, %m6, !dbg !39
    #dbg_value(i32 %7, !17, !DIExpression(), !24)
  %8 = add nuw nsw i32 %5, 1, !dbg !40
    #dbg_value(i32 %8, !18, !DIExpression(), !25)
  %9 = icmp eq i32 %5, 0, !dbg !41
  br i1 %9, label %3, label %1, !dbg !26, !llvm.loop !42
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !46 {
  %1 = tail call i32 @slice(), !dbg !47
  ret i32 %1, !dbg !48
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
!8 = !DIFile(filename: "w2h_phase_inloop_invread.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "57cc393e6aba321b771ada96a985d52f")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !11, file: !11, line: 5, type: !12, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "./w2h_phase_inloop_invread.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "57cc393e6aba321b771ada96a985d52f")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18, !20}
!16 = !DILocalVariable(name: "y", scope: !10, file: !11, line: 6, type: !14)
!17 = !DILocalVariable(name: "s", scope: !10, file: !11, line: 7, type: !14)
!18 = !DILocalVariable(name: "k", scope: !19, file: !11, line: 8, type: !14)
!19 = distinct !DILexicalBlock(scope: !10, file: !11, line: 8, column: 5)
!20 = !DILocalVariable(name: "u", scope: !21, file: !11, line: 9, type: !14)
!21 = distinct !DILexicalBlock(scope: !22, file: !11, line: 8, column: 33)
!22 = distinct !DILexicalBlock(scope: !19, file: !11, line: 8, column: 5)
!23 = !DILocation(line: 6, column: 14, scope: !10)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 0, scope: !19)
!26 = !DILocation(line: 8, column: 5, scope: !19)
!27 = !DILocation(line: 13, column: 16, scope: !10)
!28 = !DILocation(line: 13, column: 14, scope: !10)
!29 = !DILocation(line: 13, column: 5, scope: !10)
!30 = !DILocation(line: 9, column: 17, scope: !21)
!31 = !DILocation(line: 0, scope: !21)
!32 = !DILocation(line: 10, column: 22, scope: !33)
!33 = distinct !DILexicalBlock(scope: !21, file: !11, line: 10, column: 13)
!34 = !DILocation(line: 10, column: 27, scope: !33)
!35 = !{}
!36 = !DILocation(line: 11, column: 14, scope: !21)
!37 = !DILocation(line: 11, column: 41, scope: !21)
!38 = !DILocation(line: 11, column: 39, scope: !21)
!39 = !DILocation(line: 11, column: 11, scope: !21)
!40 = !DILocation(line: 8, column: 28, scope: !22)
!41 = !DILocation(line: 8, column: 23, scope: !22)
!42 = distinct !{!42, !26, !43, !44, !45}
!43 = !DILocation(line: 12, column: 5, scope: !19)
!44 = !{!"llvm.loop.mustprogress"}
!45 = !{!"llvm.loop.unroll.disable"}
!46 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 15, type: !12, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!47 = !DILocation(line: 15, column: 25, scope: !46)
!48 = !DILocation(line: 15, column: 18, scope: !46)
