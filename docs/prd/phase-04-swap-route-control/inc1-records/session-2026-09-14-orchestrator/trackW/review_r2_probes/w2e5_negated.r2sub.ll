; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.hdTYGAtUcr/s1.ll'
source_filename = "./w2e5_negated.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !23
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !23
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !24)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !25
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !25
    #dbg_value(i32 %h1, !19, !DIExpression(), !24)
    #dbg_value(i32 0, !20, !DIExpression(), !24)
    #dbg_value(i32 0, !21, !DIExpression(), !26)
  br label %5, !dbg !27

1:                                                ; preds = %5
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !28
  %2 = add nsw i32 %m, 2, !dbg !29
  %m2 = call i1 @cqrt_measure_i1(i32 %h), !dbg !30
  %3 = zext i1 %m2 to i32, !dbg !30
  %4 = add nsw i32 %2, %3, !dbg !31
  ret i32 %4, !dbg !32

5:                                                ; preds = %5, %0
  %6 = phi i32 [ 0, %0 ], [ %7, %5 ]
    #dbg_value(i32 %6, !21, !DIExpression(), !26)
    #dbg_value(i32 %6, !20, !DIExpression(), !24)
    #dbg_value(i32 %h1, !19, !DIExpression(), !24)
  call void @cqrt_ry_i32(i32 %h1, double 3.000000e-01), !dbg !33
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double -3.000000e-01), !dbg !37
    #dbg_value(i32 %h1, !19, !DIExpression(), !24)
  %7 = add nuw nsw i32 %6, 1, !dbg !38
    #dbg_value(i32 %7, !20, !DIExpression(), !24)
    #dbg_value(i32 %7, !21, !DIExpression(), !26)
  %8 = icmp eq i32 %6, 0, !dbg !39
  br i1 %8, label %5, label %1, !dbg !27, !llvm.loop !40
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !44 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !45
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !45
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !47)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !48
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !48
    #dbg_value(i32 %h1, !19, !DIExpression(), !47)
    #dbg_value(i32 0, !20, !DIExpression(), !47)
    #dbg_value(i32 0, !21, !DIExpression(), !49)
  br label %1, !dbg !50

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %3, %1 ]
    #dbg_value(i32 %2, !21, !DIExpression(), !49)
    #dbg_value(i32 %2, !20, !DIExpression(), !47)
    #dbg_value(i32 %h1, !19, !DIExpression(), !47)
  call void @cqrt_ry_i32(i32 %h1, double 3.000000e-01), !dbg !51
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double -3.000000e-01), !dbg !52
    #dbg_value(i32 %h1, !19, !DIExpression(), !47)
  %3 = add nuw nsw i32 %2, 1, !dbg !53
    #dbg_value(i32 %3, !20, !DIExpression(), !47)
    #dbg_value(i32 %3, !21, !DIExpression(), !49)
  %4 = icmp eq i32 %2, 0, !dbg !54
  br i1 %4, label %1, label %5, !dbg !50, !llvm.loop !55

5:                                                ; preds = %1
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !57
  %6 = add nsw i32 %m, 2, !dbg !58
  %m2 = call i1 @cqrt_measure_i1(i32 %h), !dbg !59
  %7 = zext i1 %m2 to i32, !dbg !59
  %8 = add nsw i32 %6, %7, !dbg !60
  ret i32 %8, !dbg !61
}

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

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
!8 = !DIFile(filename: "w2e5_negated.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "4d3c6da5855058ca34cfa54c205e7c5c")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2e5_negated.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "4d3c6da5855058ca34cfa54c205e7c5c")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 4, type: !10)
!19 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 5, type: !16)
!20 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 6, type: !16)
!21 = !DILocalVariable(name: "k", scope: !22, file: !13, line: 7, type: !16)
!22 = distinct !DILexicalBlock(scope: !12, file: !13, line: 7, column: 5)
!23 = !DILocation(line: 4, column: 14, scope: !12)
!24 = !DILocation(line: 0, scope: !12)
!25 = !DILocation(line: 5, column: 14, scope: !12)
!26 = !DILocation(line: 0, scope: !22)
!27 = !DILocation(line: 7, column: 5, scope: !22)
!28 = !DILocation(line: 11, column: 16, scope: !12)
!29 = !DILocation(line: 11, column: 14, scope: !12)
!30 = !DILocation(line: 11, column: 32, scope: !12)
!31 = !DILocation(line: 11, column: 30, scope: !12)
!32 = !DILocation(line: 11, column: 5, scope: !12)
!33 = !DILocation(line: 8, column: 21, scope: !34)
!34 = distinct !DILexicalBlock(scope: !35, file: !13, line: 8, column: 13)
!35 = distinct !DILexicalBlock(scope: !36, file: !13, line: 7, column: 33)
!36 = distinct !DILexicalBlock(scope: !22, file: !13, line: 7, column: 5)
!37 = !DILocation(line: 8, column: 13, scope: !35)
!38 = !DILocation(line: 7, column: 28, scope: !36)
!39 = !DILocation(line: 7, column: 23, scope: !36)
!40 = distinct !{!40, !27, !41, !42, !43}
!41 = !DILocation(line: 10, column: 5, scope: !22)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 13, type: !14, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!45 = !DILocation(line: 4, column: 14, scope: !12, inlinedAt: !46)
!46 = distinct !DILocation(line: 13, column: 25, scope: !44)
!47 = !DILocation(line: 0, scope: !12, inlinedAt: !46)
!48 = !DILocation(line: 5, column: 14, scope: !12, inlinedAt: !46)
!49 = !DILocation(line: 0, scope: !22, inlinedAt: !46)
!50 = !DILocation(line: 7, column: 5, scope: !22, inlinedAt: !46)
!51 = !DILocation(line: 8, column: 21, scope: !34, inlinedAt: !46)
!52 = !DILocation(line: 8, column: 13, scope: !35, inlinedAt: !46)
!53 = !DILocation(line: 7, column: 28, scope: !36, inlinedAt: !46)
!54 = !DILocation(line: 7, column: 23, scope: !36, inlinedAt: !46)
!55 = distinct !{!55, !50, !56, !42, !43}
!56 = !DILocation(line: 10, column: 5, scope: !22, inlinedAt: !46)
!57 = !DILocation(line: 11, column: 16, scope: !12, inlinedAt: !46)
!58 = !DILocation(line: 11, column: 14, scope: !12, inlinedAt: !46)
!59 = !DILocation(line: 11, column: 32, scope: !12, inlinedAt: !46)
!60 = !DILocation(line: 11, column: 30, scope: !12, inlinedAt: !46)
!61 = !DILocation(line: 13, column: 18, scope: !44)
