; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.mQzBXgzL8I/s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/w2h_phase_inloop_invread.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !22
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !22
    #dbg_value(i32 %h, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
  br label %3, !dbg !25

1:                                                ; preds = %3
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !26
  %2 = add nsw i32 %m, %7, !dbg !27
  ret i32 %2, !dbg !28

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %8, %3 ]
    #dbg_value(i32 %4, !16, !DIExpression(), !23)
    #dbg_value(i32 %5, !17, !DIExpression(), !24)
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !29
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !29
    #dbg_value(i32 %h1, !19, !DIExpression(), !30)
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h1, i32 2), !dbg !31
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op2, i32 0), !dbg !31
  call void @cqrt_x(i32 %h_cmp), !dbg !33
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01), !dbg !33, !cq.branchphase !34
  call void @cqrt_x(i32 %h_cmp), !dbg !33
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op2, i32 0), !dbg !31
  call void @cqrt_free(i32 %h_cmp), !dbg !33
  %h_op3 = call i32 @cq_template_lshr_i32_hl(i32 %h1, i32 2), !dbg !35
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h_op3, i32 1), !dbg !35
  %m5 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !35
  %m6 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !36
  %6 = add i32 %m5, %4, !dbg !37
  %7 = add i32 %6, %m6, !dbg !38
    #dbg_value(i32 %7, !16, !DIExpression(), !23)
  %8 = add nuw nsw i32 %5, 1, !dbg !39
    #dbg_value(i32 %8, !17, !DIExpression(), !24)
  %9 = icmp eq i32 %5, 0, !dbg !40
  br i1 %9, label %3, label %1, !dbg !25, !llvm.loop !41
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !45 {
  %1 = tail call i32 @slice(), !dbg !46
  ret i32 %1, !dbg !47
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackS/probes/w2h_phase_inloop_invread.c", directory: "/Users/sorenwilkening/Desktop/CQ_s82e", checksumkind: CSK_MD5, checksum: "57cc393e6aba321b771ada96a985d52f")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 8, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 9, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 8, column: 33)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!22 = !DILocation(line: 6, column: 14, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 8, column: 5, scope: !18)
!26 = !DILocation(line: 13, column: 16, scope: !10)
!27 = !DILocation(line: 13, column: 14, scope: !10)
!28 = !DILocation(line: 13, column: 5, scope: !10)
!29 = !DILocation(line: 9, column: 17, scope: !20)
!30 = !DILocation(line: 0, scope: !20)
!31 = !DILocation(line: 10, column: 22, scope: !32)
!32 = distinct !DILexicalBlock(scope: !20, file: !8, line: 10, column: 13)
!33 = !DILocation(line: 10, column: 27, scope: !32)
!34 = !{}
!35 = !DILocation(line: 11, column: 14, scope: !20)
!36 = !DILocation(line: 11, column: 41, scope: !20)
!37 = !DILocation(line: 11, column: 39, scope: !20)
!38 = !DILocation(line: 11, column: 11, scope: !20)
!39 = !DILocation(line: 8, column: 28, scope: !21)
!40 = !DILocation(line: 8, column: 23, scope: !21)
!41 = distinct !{!41, !25, !42, !43, !44}
!42 = !DILocation(line: 12, column: 5, scope: !18)
!43 = !{!"llvm.loop.mustprogress"}
!44 = !{!"llvm.loop.unroll.disable"}
!45 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!46 = !DILocation(line: 15, column: 25, scope: !45)
!47 = !DILocation(line: 15, column: 18, scope: !45)
