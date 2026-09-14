; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.hJuZeIBr9j/s1.ll'
source_filename = "./w2e7_stateprep.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !25
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !25
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !26)
    #dbg_value(i32 0, !19, !DIExpression(), !26)
    #dbg_value(i32 0, !20, !DIExpression(), !27)
  br label %4, !dbg !28

1:                                                ; preds = %4
  %m = call i1 @cqrt_measure_i1(i32 %h), !dbg !29
  %2 = zext i1 %m to i32, !dbg !29
  %3 = add nsw i32 %7, %2, !dbg !30
  ret i32 %3, !dbg !31

4:                                                ; preds = %4, %0
  %5 = phi i32 [ 0, %0 ], [ %8, %4 ]
  %6 = phi i32 [ 0, %0 ], [ %7, %4 ]
    #dbg_value(i32 %5, !20, !DIExpression(), !27)
    #dbg_value(i32 %6, !19, !DIExpression(), !26)
    #dbg_value(i32 4, !22, !DIExpression(), !32)
  %h1 = call i32 @cqrt_alloc_i32(i32 4), !dbg !33
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 3.000000e-01), !dbg !33
    #dbg_value(i32 %h1, !22, !DIExpression(), !32)
  %m2 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !35
  %7 = add nsw i32 %m2, %6, !dbg !36
    #dbg_value(i32 %7, !19, !DIExpression(), !26)
  %8 = add nuw nsw i32 %5, 1, !dbg !37
    #dbg_value(i32 %8, !20, !DIExpression(), !27)
  %9 = icmp eq i32 %5, 0, !dbg !38
  br i1 %9, label %4, label %1, !dbg !28, !llvm.loop !39
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !43 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !44
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !44
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !46)
    #dbg_value(i32 0, !19, !DIExpression(), !46)
    #dbg_value(i32 0, !20, !DIExpression(), !47)
  br label %1, !dbg !48

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !20, !DIExpression(), !47)
    #dbg_value(i32 %3, !19, !DIExpression(), !46)
    #dbg_value(i32 4, !22, !DIExpression(), !49)
  %h1 = call i32 @cqrt_alloc_i32(i32 4), !dbg !50
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 3.000000e-01), !dbg !50
    #dbg_value(i32 %h1, !22, !DIExpression(), !49)
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !51
  %4 = add nsw i32 %m, %3, !dbg !52
    #dbg_value(i32 %4, !19, !DIExpression(), !46)
  %5 = add nuw nsw i32 %2, 1, !dbg !53
    #dbg_value(i32 %5, !20, !DIExpression(), !47)
  %6 = icmp eq i32 %2, 0, !dbg !54
  br i1 %6, label %1, label %7, !dbg !48, !llvm.loop !55

7:                                                ; preds = %1
  %m2 = call i1 @cqrt_measure_i1(i32 %h), !dbg !57
  %8 = zext i1 %m2 to i32, !dbg !57
  %9 = add nsw i32 %4, %8, !dbg !58
  ret i32 %9, !dbg !59
}

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i1 @cqrt_measure_i1(i32)

declare i32 @cqrt_measure_i32(i32)

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
!8 = !DIFile(filename: "w2e7_stateprep.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "99e18581ff273652aa16833bea8ef58c")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 4, type: !14, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2e7_stateprep.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "99e18581ff273652aa16833bea8ef58c")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !22}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 5, type: !10)
!19 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 6, type: !16)
!20 = !DILocalVariable(name: "k", scope: !21, file: !13, line: 7, type: !16)
!21 = distinct !DILexicalBlock(scope: !12, file: !13, line: 7, column: 5)
!22 = !DILocalVariable(name: "r", scope: !23, file: !13, line: 8, type: !16)
!23 = distinct !DILexicalBlock(scope: !24, file: !13, line: 7, column: 33)
!24 = distinct !DILexicalBlock(scope: !21, file: !13, line: 7, column: 5)
!25 = !DILocation(line: 5, column: 14, scope: !12)
!26 = !DILocation(line: 0, scope: !12)
!27 = !DILocation(line: 0, scope: !21)
!28 = !DILocation(line: 7, column: 5, scope: !21)
!29 = !DILocation(line: 12, column: 16, scope: !12)
!30 = !DILocation(line: 12, column: 14, scope: !12)
!31 = !DILocation(line: 12, column: 5, scope: !12)
!32 = !DILocation(line: 0, scope: !23)
!33 = !DILocation(line: 9, column: 20, scope: !34)
!34 = distinct !DILexicalBlock(scope: !23, file: !13, line: 9, column: 13)
!35 = !DILocation(line: 10, column: 14, scope: !23)
!36 = !DILocation(line: 10, column: 11, scope: !23)
!37 = !DILocation(line: 7, column: 28, scope: !24)
!38 = !DILocation(line: 7, column: 23, scope: !24)
!39 = distinct !{!39, !28, !40, !41, !42}
!40 = !DILocation(line: 11, column: 5, scope: !21)
!41 = !{!"llvm.loop.mustprogress"}
!42 = !{!"llvm.loop.unroll.disable"}
!43 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 14, type: !14, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!44 = !DILocation(line: 5, column: 14, scope: !12, inlinedAt: !45)
!45 = distinct !DILocation(line: 14, column: 25, scope: !43)
!46 = !DILocation(line: 0, scope: !12, inlinedAt: !45)
!47 = !DILocation(line: 0, scope: !21, inlinedAt: !45)
!48 = !DILocation(line: 7, column: 5, scope: !21, inlinedAt: !45)
!49 = !DILocation(line: 0, scope: !23, inlinedAt: !45)
!50 = !DILocation(line: 9, column: 20, scope: !34, inlinedAt: !45)
!51 = !DILocation(line: 10, column: 14, scope: !23, inlinedAt: !45)
!52 = !DILocation(line: 10, column: 11, scope: !23, inlinedAt: !45)
!53 = !DILocation(line: 7, column: 28, scope: !24, inlinedAt: !45)
!54 = !DILocation(line: 7, column: 23, scope: !24, inlinedAt: !45)
!55 = distinct !{!55, !48, !56, !41, !42}
!56 = !DILocation(line: 11, column: 5, scope: !21, inlinedAt: !45)
!57 = !DILocation(line: 12, column: 16, scope: !12, inlinedAt: !45)
!58 = !DILocation(line: 12, column: 14, scope: !12, inlinedAt: !45)
!59 = !DILocation(line: 14, column: 18, scope: !43)
