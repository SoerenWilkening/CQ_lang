; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.s4IuefhhN3/s1.ll'
source_filename = "./v1_wa.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !22
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !22
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !23)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !24
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !24
    #dbg_value(i32 %h1, !19, !DIExpression(), !23)
    #dbg_value(i32 0, !20, !DIExpression(), !25)
  br label %4, !dbg !26

1:                                                ; preds = %4
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !27
  %m2 = call i1 @cqrt_measure_i1(i32 %h), !dbg !28
  %2 = zext i1 %m2 to i32, !dbg !28
  %3 = add nsw i32 %m, %2, !dbg !29
  ret i32 %3, !dbg !30

4:                                                ; preds = %4, %0
  %5 = phi i32 [ 0, %0 ], [ %6, %4 ]
    #dbg_value(i32 %5, !20, !DIExpression(), !25)
    #dbg_value(i32 %h1, !19, !DIExpression(), !23)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 2.000000e-01), !dbg !31
    #dbg_value(i32 %h1, !19, !DIExpression(), !23)
  %6 = add nuw nsw i32 %5, 1, !dbg !35
    #dbg_value(i32 %6, !20, !DIExpression(), !25)
  %7 = icmp eq i32 %5, 0, !dbg !36
  br i1 %7, label %4, label %1, !dbg !26, !llvm.loop !37
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !41 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !42
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !42
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !44)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !45
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !45
    #dbg_value(i32 %h1, !19, !DIExpression(), !44)
    #dbg_value(i32 0, !20, !DIExpression(), !46)
  br label %1, !dbg !47

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %3, %1 ]
    #dbg_value(i32 %2, !20, !DIExpression(), !46)
    #dbg_value(i32 %h1, !19, !DIExpression(), !44)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 2.000000e-01), !dbg !48
    #dbg_value(i32 %h1, !19, !DIExpression(), !44)
  %3 = add nuw nsw i32 %2, 1, !dbg !49
    #dbg_value(i32 %3, !20, !DIExpression(), !46)
  %4 = icmp eq i32 %2, 0, !dbg !50
  br i1 %4, label %1, label %5, !dbg !47, !llvm.loop !51

5:                                                ; preds = %1
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !53
  %m2 = call i1 @cqrt_measure_i1(i32 %h), !dbg !54
  %6 = zext i1 %m2 to i32, !dbg !54
  %7 = add nsw i32 %m, %6, !dbg !55
  ret i32 %7, !dbg !56
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
!8 = !DIFile(filename: "v1_wa.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "b505744a3a3c95db10f264f439cf5d5c")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 7, type: !14, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./v1_wa.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "b505744a3a3c95db10f264f439cf5d5c")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 8, type: !10)
!19 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 9, type: !16)
!20 = !DILocalVariable(name: "k", scope: !21, file: !13, line: 10, type: !16)
!21 = distinct !DILexicalBlock(scope: !12, file: !13, line: 10, column: 5)
!22 = !DILocation(line: 8, column: 14, scope: !12)
!23 = !DILocation(line: 0, scope: !12)
!24 = !DILocation(line: 9, column: 13, scope: !12)
!25 = !DILocation(line: 0, scope: !21)
!26 = !DILocation(line: 10, column: 5, scope: !21)
!27 = !DILocation(line: 11, column: 12, scope: !12)
!28 = !DILocation(line: 11, column: 28, scope: !12)
!29 = !DILocation(line: 11, column: 26, scope: !12)
!30 = !DILocation(line: 11, column: 5, scope: !12)
!31 = !DILocation(line: 10, column: 49, scope: !32)
!32 = distinct !DILexicalBlock(scope: !33, file: !13, line: 10, column: 42)
!33 = distinct !DILexicalBlock(scope: !34, file: !13, line: 10, column: 36)
!34 = distinct !DILexicalBlock(scope: !21, file: !13, line: 10, column: 5)
!35 = !DILocation(line: 10, column: 31, scope: !34)
!36 = !DILocation(line: 10, column: 23, scope: !34)
!37 = distinct !{!37, !26, !38, !39, !40}
!38 = !DILocation(line: 10, column: 67, scope: !21)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !{!"llvm.loop.unroll.disable"}
!41 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 13, type: !14, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!42 = !DILocation(line: 8, column: 14, scope: !12, inlinedAt: !43)
!43 = distinct !DILocation(line: 13, column: 25, scope: !41)
!44 = !DILocation(line: 0, scope: !12, inlinedAt: !43)
!45 = !DILocation(line: 9, column: 13, scope: !12, inlinedAt: !43)
!46 = !DILocation(line: 0, scope: !21, inlinedAt: !43)
!47 = !DILocation(line: 10, column: 5, scope: !21, inlinedAt: !43)
!48 = !DILocation(line: 10, column: 49, scope: !32, inlinedAt: !43)
!49 = !DILocation(line: 10, column: 31, scope: !34, inlinedAt: !43)
!50 = !DILocation(line: 10, column: 23, scope: !34, inlinedAt: !43)
!51 = distinct !{!51, !47, !52, !39, !40}
!52 = !DILocation(line: 10, column: 67, scope: !21, inlinedAt: !43)
!53 = !DILocation(line: 11, column: 12, scope: !12, inlinedAt: !43)
!54 = !DILocation(line: 11, column: 28, scope: !12, inlinedAt: !43)
!55 = !DILocation(line: 11, column: 26, scope: !12, inlinedAt: !43)
!56 = !DILocation(line: 13, column: 18, scope: !41)
