; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/od7_grover_rolled_customer.ll'
source_filename = "src/od7_grover_rolled_customer.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !19
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !19
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
  br label %2, !dbg !22

1:                                                ; preds = %2
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !23
    #dbg_value(i32 %m, !16, !DIExpression(), !20)
  ret i32 %m, !dbg !24

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %4, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !21)
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
  call void @cqrt_ry_i32(i32 %h, double 2.000000e-01), !dbg !25
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5), !dbg !28
  call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !dbg !30, !cq.branchphase !31
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5), !dbg !28
  call void @cqrt_free(i32 %h_cmp), !dbg !30
  %4 = add nuw nsw i32 %3, 1, !dbg !32
    #dbg_value(i32 %4, !17, !DIExpression(), !21)
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
  %5 = icmp eq i32 %4, 3, !dbg !33
  br i1 %5, label %1, label %2, !dbg !22, !llvm.loop !34
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

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
!8 = !DIFile(filename: "src/od7_grover_rolled_customer.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "d931f8d56af8dd4722b740992ab3e848")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 4, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!19 = !DILocation(line: 3, column: 23, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 4, column: 3, scope: !18)
!23 = !DILocation(line: 5, column: 6, scope: !10)
!24 = !DILocation(line: 5, column: 21, scope: !10)
!25 = !DILocation(line: 4, column: 27, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !8, line: 4, column: 23)
!27 = distinct !DILexicalBlock(scope: !18, file: !8, line: 4, column: 3)
!28 = !DILocation(line: 4, column: 48, scope: !29)
!29 = distinct !DILexicalBlock(scope: !26, file: !8, line: 4, column: 47)
!30 = !DILocation(line: 4, column: 53, scope: !29)
!31 = !{}
!32 = !DILocation(line: 4, column: 20, scope: !27)
!33 = !DILocation(line: 4, column: 16, scope: !27)
!34 = distinct !{!34, !22, !35, !36, !37}
!35 = !DILocation(line: 4, column: 70, scope: !18)
!36 = !{!"llvm.loop.mustprogress"}
!37 = !{!"llvm.loop.unroll.disable"}
