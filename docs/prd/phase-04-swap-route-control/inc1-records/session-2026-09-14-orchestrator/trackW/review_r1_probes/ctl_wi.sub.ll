; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.umdSvRdb9N/s1.ll'
source_filename = "./ctl_wi.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
    #dbg_value(i32 0, !18, !DIExpression(), !25)
    #dbg_value(i32 0, !19, !DIExpression(), !26)
  br label %2, !dbg !27

1:                                                ; preds = %2
  ret i32 %7, !dbg !28

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %7, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %8, %2 ]
    #dbg_value(i32 %3, !18, !DIExpression(), !25)
    #dbg_value(i32 %4, !19, !DIExpression(), !26)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !29
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !29
    #dbg_value(i32 %h, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !30)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !31
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !31
    #dbg_value(i32 %h1, !24, !DIExpression(), !30)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 2.000000e-01), !dbg !32
    #dbg_value(i32 %h1, !24, !DIExpression(), !30)
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !34
  %m2 = call i1 @cqrt_measure_i1(i32 %h), !dbg !35
  %5 = zext i1 %m2 to i32, !dbg !35
  %6 = add i32 %m, %3, !dbg !36
  %7 = add i32 %6, %5, !dbg !37
    #dbg_value(i32 %7, !18, !DIExpression(), !25)
  %8 = add nuw nsw i32 %4, 1, !dbg !38
    #dbg_value(i32 %8, !19, !DIExpression(), !26)
  %9 = icmp eq i32 %4, 0, !dbg !39
  br i1 %9, label %2, label %1, !dbg !27, !llvm.loop !40
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !44 {
    #dbg_value(i32 0, !18, !DIExpression(), !45)
    #dbg_value(i32 0, !19, !DIExpression(), !47)
  br label %1, !dbg !48

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %6, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %7, %1 ]
    #dbg_value(i32 %2, !18, !DIExpression(), !45)
    #dbg_value(i32 %3, !19, !DIExpression(), !47)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !49
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !49
    #dbg_value(i32 %h, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !50)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !51
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !51
    #dbg_value(i32 %h1, !24, !DIExpression(), !50)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 2.000000e-01), !dbg !52
    #dbg_value(i32 %h1, !24, !DIExpression(), !50)
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !53
  %m2 = call i1 @cqrt_measure_i1(i32 %h), !dbg !54
  %4 = zext i1 %m2 to i32, !dbg !54
  %5 = add i32 %m, %2, !dbg !55
  %6 = add i32 %5, %4, !dbg !56
    #dbg_value(i32 %6, !18, !DIExpression(), !45)
  %7 = add nuw nsw i32 %3, 1, !dbg !57
    #dbg_value(i32 %7, !19, !DIExpression(), !47)
  %8 = icmp eq i32 %3, 0, !dbg !58
  br i1 %8, label %1, label %9, !dbg !48, !llvm.loop !59

9:                                                ; preds = %1
  ret i32 %6, !dbg !61
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
!8 = !DIFile(filename: "ctl_wi.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "8f40a027c124fe8da0885511f3bed4eb")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 8, type: !14, scopeLine: 8, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./ctl_wi.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "8f40a027c124fe8da0885511f3bed4eb")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !21, !24}
!18 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 9, type: !16)
!19 = !DILocalVariable(name: "k", scope: !20, file: !13, line: 10, type: !16)
!20 = distinct !DILexicalBlock(scope: !12, file: !13, line: 10, column: 5)
!21 = !DILocalVariable(name: "t", scope: !22, file: !13, line: 11, type: !10)
!22 = distinct !DILexicalBlock(scope: !23, file: !13, line: 10, column: 36)
!23 = distinct !DILexicalBlock(scope: !20, file: !13, line: 10, column: 5)
!24 = !DILocalVariable(name: "r", scope: !22, file: !13, line: 12, type: !16)
!25 = !DILocation(line: 0, scope: !12)
!26 = !DILocation(line: 0, scope: !20)
!27 = !DILocation(line: 10, column: 5, scope: !20)
!28 = !DILocation(line: 16, column: 5, scope: !12)
!29 = !DILocation(line: 11, column: 18, scope: !22)
!30 = !DILocation(line: 0, scope: !22)
!31 = !DILocation(line: 12, column: 17, scope: !22)
!32 = !DILocation(line: 13, column: 20, scope: !33)
!33 = distinct !DILexicalBlock(scope: !22, file: !13, line: 13, column: 13)
!34 = !DILocation(line: 14, column: 14, scope: !22)
!35 = !DILocation(line: 14, column: 30, scope: !22)
!36 = !DILocation(line: 14, column: 28, scope: !22)
!37 = !DILocation(line: 14, column: 11, scope: !22)
!38 = !DILocation(line: 10, column: 31, scope: !23)
!39 = !DILocation(line: 10, column: 23, scope: !23)
!40 = distinct !{!40, !27, !41, !42, !43}
!41 = !DILocation(line: 15, column: 5, scope: !20)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 18, type: !14, scopeLine: 18, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!45 = !DILocation(line: 0, scope: !12, inlinedAt: !46)
!46 = distinct !DILocation(line: 18, column: 25, scope: !44)
!47 = !DILocation(line: 0, scope: !20, inlinedAt: !46)
!48 = !DILocation(line: 10, column: 5, scope: !20, inlinedAt: !46)
!49 = !DILocation(line: 11, column: 18, scope: !22, inlinedAt: !46)
!50 = !DILocation(line: 0, scope: !22, inlinedAt: !46)
!51 = !DILocation(line: 12, column: 17, scope: !22, inlinedAt: !46)
!52 = !DILocation(line: 13, column: 20, scope: !33, inlinedAt: !46)
!53 = !DILocation(line: 14, column: 14, scope: !22, inlinedAt: !46)
!54 = !DILocation(line: 14, column: 30, scope: !22, inlinedAt: !46)
!55 = !DILocation(line: 14, column: 28, scope: !22, inlinedAt: !46)
!56 = !DILocation(line: 14, column: 11, scope: !22, inlinedAt: !46)
!57 = !DILocation(line: 10, column: 31, scope: !23, inlinedAt: !46)
!58 = !DILocation(line: 10, column: 23, scope: !23, inlinedAt: !46)
!59 = distinct !{!59, !48, !60, !42, !43}
!60 = !DILocation(line: 15, column: 5, scope: !20, inlinedAt: !46)
!61 = !DILocation(line: 18, column: 18, scope: !44)
