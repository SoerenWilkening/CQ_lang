; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.jHNVT4XLse/s1.ll'
source_filename = "./w2c_inplace_cmp.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !21
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !21
    #dbg_value(i32 %h, !16, !DIExpression(), !22)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !23
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !23
    #dbg_value(i32 %h1, !17, !DIExpression(), !22)
    #dbg_value(i32 0, !18, !DIExpression(), !22)
    #dbg_value(i32 0, !19, !DIExpression(), !24)
    #dbg_value(i32 %h, !16, !DIExpression(), !22)
  br label %3, !dbg !25

1:                                                ; preds = %3
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !26
  %2 = add nsw i32 %m, %6, !dbg !27
  ret i32 %2, !dbg !28

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %6, %3 ]
    #dbg_value(i32 %4, !19, !DIExpression(), !24)
    #dbg_value(i32 %5, !18, !DIExpression(), !22)
    #dbg_value(i32 %h1, !17, !DIExpression(), !22)
    #dbg_value(i32 %h, !16, !DIExpression(), !22)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5), !dbg !29
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 9.000000e-01), !dbg !33
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5), !dbg !29
  call void @cqrt_free(i32 %h_cmp), !dbg !34
    #dbg_value(i32 %h1, !17, !DIExpression(), !22)
  call void @cqrt_addc_i32(i32 %h, i32 3), !dbg !35
    #dbg_value(i32 %h, !16, !DIExpression(), !22)
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !36
  %6 = add nsw i32 %m2, %5, !dbg !37
    #dbg_value(i32 %6, !18, !DIExpression(), !22)
  %7 = add nuw nsw i32 %4, 1, !dbg !38
    #dbg_value(i32 %7, !19, !DIExpression(), !24)
  %8 = icmp eq i32 %4, 0, !dbg !39
  br i1 %8, label %3, label %1, !dbg !25, !llvm.loop !40
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !44 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !45
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !45
    #dbg_value(i32 %h, !16, !DIExpression(), !47)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !48
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !48
    #dbg_value(i32 %h1, !17, !DIExpression(), !47)
    #dbg_value(i32 0, !18, !DIExpression(), !47)
    #dbg_value(i32 0, !19, !DIExpression(), !49)
    #dbg_value(i32 %h, !16, !DIExpression(), !47)
  br label %1, !dbg !50

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !19, !DIExpression(), !49)
    #dbg_value(i32 %3, !18, !DIExpression(), !47)
    #dbg_value(i32 %h1, !17, !DIExpression(), !47)
    #dbg_value(i32 %h, !16, !DIExpression(), !47)
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5), !dbg !51
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 9.000000e-01), !dbg !52
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5), !dbg !51
  call void @cqrt_free(i32 %h_cmp), !dbg !53
    #dbg_value(i32 %h1, !17, !DIExpression(), !47)
  call void @cqrt_addc_i32(i32 %h, i32 3), !dbg !54
    #dbg_value(i32 %h, !16, !DIExpression(), !47)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !55
  %4 = add nsw i32 %m, %3, !dbg !56
    #dbg_value(i32 %4, !18, !DIExpression(), !47)
  %5 = add nuw nsw i32 %2, 1, !dbg !57
    #dbg_value(i32 %5, !19, !DIExpression(), !49)
  %6 = icmp eq i32 %2, 0, !dbg !58
  br i1 %6, label %1, label %7, !dbg !50, !llvm.loop !59

7:                                                ; preds = %1
  %m2 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !61
  %8 = add nsw i32 %m2, %4, !dbg !62
  ret i32 %8, !dbg !63
}

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_x(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare void @cqrt_addc_i32(i32, i32)

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
!8 = !DIFile(filename: "w2c_inplace_cmp.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "8c934ab10cd259e8f140c2af4b2d307c")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !11, file: !11, line: 5, type: !12, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "./w2c_inplace_cmp.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "8c934ab10cd259e8f140c2af4b2d307c")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18, !19}
!16 = !DILocalVariable(name: "q", scope: !10, file: !11, line: 6, type: !14)
!17 = !DILocalVariable(name: "r", scope: !10, file: !11, line: 7, type: !14)
!18 = !DILocalVariable(name: "s", scope: !10, file: !11, line: 8, type: !14)
!19 = !DILocalVariable(name: "k", scope: !20, file: !11, line: 9, type: !14)
!20 = distinct !DILexicalBlock(scope: !10, file: !11, line: 9, column: 5)
!21 = !DILocation(line: 6, column: 14, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 7, column: 14, scope: !10)
!24 = !DILocation(line: 0, scope: !20)
!25 = !DILocation(line: 9, column: 5, scope: !20)
!26 = !DILocation(line: 14, column: 16, scope: !10)
!27 = !DILocation(line: 14, column: 14, scope: !10)
!28 = !DILocation(line: 14, column: 5, scope: !10)
!29 = !DILocation(line: 10, column: 15, scope: !30)
!30 = distinct !DILexicalBlock(scope: !31, file: !11, line: 10, column: 13)
!31 = distinct !DILexicalBlock(scope: !32, file: !11, line: 9, column: 33)
!32 = distinct !DILexicalBlock(scope: !20, file: !11, line: 9, column: 5)
!33 = !DILocation(line: 10, column: 25, scope: !30)
!34 = !DILocation(line: 10, column: 13, scope: !31)
!35 = !DILocation(line: 11, column: 15, scope: !31)
!36 = !DILocation(line: 12, column: 14, scope: !31)
!37 = !DILocation(line: 12, column: 11, scope: !31)
!38 = !DILocation(line: 9, column: 28, scope: !32)
!39 = !DILocation(line: 9, column: 23, scope: !32)
!40 = distinct !{!40, !25, !41, !42, !43}
!41 = !DILocation(line: 13, column: 5, scope: !20)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 16, type: !12, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!45 = !DILocation(line: 6, column: 14, scope: !10, inlinedAt: !46)
!46 = distinct !DILocation(line: 16, column: 25, scope: !44)
!47 = !DILocation(line: 0, scope: !10, inlinedAt: !46)
!48 = !DILocation(line: 7, column: 14, scope: !10, inlinedAt: !46)
!49 = !DILocation(line: 0, scope: !20, inlinedAt: !46)
!50 = !DILocation(line: 9, column: 5, scope: !20, inlinedAt: !46)
!51 = !DILocation(line: 10, column: 15, scope: !30, inlinedAt: !46)
!52 = !DILocation(line: 10, column: 25, scope: !30, inlinedAt: !46)
!53 = !DILocation(line: 10, column: 13, scope: !31, inlinedAt: !46)
!54 = !DILocation(line: 11, column: 15, scope: !31, inlinedAt: !46)
!55 = !DILocation(line: 12, column: 14, scope: !31, inlinedAt: !46)
!56 = !DILocation(line: 12, column: 11, scope: !31, inlinedAt: !46)
!57 = !DILocation(line: 9, column: 28, scope: !32, inlinedAt: !46)
!58 = !DILocation(line: 9, column: 23, scope: !32, inlinedAt: !46)
!59 = distinct !{!59, !50, !60, !42, !43}
!60 = !DILocation(line: 13, column: 5, scope: !20, inlinedAt: !46)
!61 = !DILocation(line: 14, column: 16, scope: !10, inlinedAt: !46)
!62 = !DILocation(line: 14, column: 14, scope: !10, inlinedAt: !46)
!63 = !DILocation(line: 16, column: 18, scope: !44)
