; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.VSyBBGHWeq/s1.ll'
source_filename = "./w2c_inplace_rail.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !24
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !24
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !25)
  %h1 = call i32 @cqrt_alloc_i32(i32 5), !dbg !26
  call void @cqrt_ry_i32(i32 %h1, double 5.000000e-01), !dbg !26
    #dbg_value(i32 %h1, !19, !DIExpression(), !25)
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !27
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01), !dbg !27
    #dbg_value(i32 %h2, !20, !DIExpression(), !25)
    #dbg_value(i32 0, !21, !DIExpression(), !25)
    #dbg_value(i32 0, !22, !DIExpression(), !28)
    #dbg_value(i32 %h1, !19, !DIExpression(), !25)
  br label %5, !dbg !29

1:                                                ; preds = %5
  %m = call i32 @cqrt_measure_i32(i32 %h2), !dbg !30
  %2 = add nsw i32 %m, %8, !dbg !31
  %m3 = call i1 @cqrt_measure_i1(i32 %h), !dbg !32
  %3 = zext i1 %m3 to i32, !dbg !32
  %4 = add nsw i32 %2, %3, !dbg !33
  ret i32 %4, !dbg !34

5:                                                ; preds = %5, %0
  %6 = phi i32 [ 0, %0 ], [ %9, %5 ]
  %7 = phi i32 [ 0, %0 ], [ %8, %5 ]
    #dbg_value(i32 %6, !22, !DIExpression(), !28)
    #dbg_value(i32 %7, !21, !DIExpression(), !25)
    #dbg_value(i32 %h2, !20, !DIExpression(), !25)
    #dbg_value(i32 %h1, !19, !DIExpression(), !25)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 3.000000e-01), !dbg !35
    #dbg_value(i32 %h2, !20, !DIExpression(), !25)
  call void @cqrt_addc_i32(i32 %h1, i32 3), !dbg !39
    #dbg_value(i32 %h1, !19, !DIExpression(), !25)
  %m4 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !40
  %8 = add nsw i32 %m4, %7, !dbg !41
    #dbg_value(i32 %8, !21, !DIExpression(), !25)
  %9 = add nuw nsw i32 %6, 1, !dbg !42
    #dbg_value(i32 %9, !22, !DIExpression(), !28)
  %10 = icmp eq i32 %6, 0, !dbg !43
  br i1 %10, label %5, label %1, !dbg !29, !llvm.loop !44
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !48 {
  %1 = tail call i32 @slice(), !dbg !49
  ret i32 %1, !dbg !50
}

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare void @cqrt_addc_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare i1 @cqrt_measure_i1(i32)

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
!8 = !DIFile(filename: "w2c_inplace_rail.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "e8dda388b0b989d0b82c0ef9022b7ef3")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 6, type: !14, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2c_inplace_rail.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "e8dda388b0b989d0b82c0ef9022b7ef3")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21, !22}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 7, type: !10)
!19 = !DILocalVariable(name: "q", scope: !12, file: !13, line: 8, type: !16)
!20 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 9, type: !16)
!21 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 10, type: !16)
!22 = !DILocalVariable(name: "k", scope: !23, file: !13, line: 11, type: !16)
!23 = distinct !DILexicalBlock(scope: !12, file: !13, line: 11, column: 5)
!24 = !DILocation(line: 7, column: 14, scope: !12)
!25 = !DILocation(line: 0, scope: !12)
!26 = !DILocation(line: 8, column: 14, scope: !12)
!27 = !DILocation(line: 9, column: 14, scope: !12)
!28 = !DILocation(line: 0, scope: !23)
!29 = !DILocation(line: 11, column: 5, scope: !23)
!30 = !DILocation(line: 16, column: 16, scope: !12)
!31 = !DILocation(line: 16, column: 14, scope: !12)
!32 = !DILocation(line: 16, column: 32, scope: !12)
!33 = !DILocation(line: 16, column: 30, scope: !12)
!34 = !DILocation(line: 16, column: 5, scope: !12)
!35 = !DILocation(line: 12, column: 20, scope: !36)
!36 = distinct !DILexicalBlock(scope: !37, file: !13, line: 12, column: 13)
!37 = distinct !DILexicalBlock(scope: !38, file: !13, line: 11, column: 33)
!38 = distinct !DILexicalBlock(scope: !23, file: !13, line: 11, column: 5)
!39 = !DILocation(line: 13, column: 15, scope: !37)
!40 = !DILocation(line: 14, column: 14, scope: !37)
!41 = !DILocation(line: 14, column: 11, scope: !37)
!42 = !DILocation(line: 11, column: 28, scope: !38)
!43 = !DILocation(line: 11, column: 23, scope: !38)
!44 = distinct !{!44, !29, !45, !46, !47}
!45 = !DILocation(line: 15, column: 5, scope: !23)
!46 = !{!"llvm.loop.mustprogress"}
!47 = !{!"llvm.loop.unroll.disable"}
!48 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 18, type: !14, scopeLine: 18, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!49 = !DILocation(line: 18, column: 25, scope: !48)
!50 = !DILocation(line: 18, column: 18, scope: !48)
