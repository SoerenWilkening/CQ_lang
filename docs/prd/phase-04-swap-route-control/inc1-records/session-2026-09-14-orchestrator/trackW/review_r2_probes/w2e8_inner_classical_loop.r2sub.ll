; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.C1ZHWKitfM/s1.ll'
source_filename = "./w2e8_inner_classical_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !27
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !27
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !28)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !29
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !29
    #dbg_value(i32 %h1, !19, !DIExpression(), !28)
    #dbg_value(i32 0, !20, !DIExpression(), !28)
    #dbg_value(i32 0, !21, !DIExpression(), !30)
  br label %5, !dbg !31

1:                                                ; preds = %5
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !32
  %2 = add nsw i32 %m, 6, !dbg !33
  %m2 = call i1 @cqrt_measure_i1(i32 %h), !dbg !34
  %3 = zext i1 %m2 to i32, !dbg !34
  %4 = add nsw i32 %2, %3, !dbg !35
  ret i32 %4, !dbg !36

5:                                                ; preds = %5, %0
  %6 = phi i32 [ 0, %0 ], [ %7, %5 ]
    #dbg_value(i32 %6, !21, !DIExpression(), !30)
    #dbg_value(i32 poison, !20, !DIExpression(), !28)
    #dbg_value(i32 %h1, !19, !DIExpression(), !28)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 3.000000e-01), !dbg !37
    #dbg_value(i32 %h1, !19, !DIExpression(), !28)
    #dbg_value(i32 0, !23, !DIExpression(), !39)
    #dbg_value(i32 poison, !20, !DIExpression(), !28)
    #dbg_value(i32 undef, !23, !DIExpression(), !39)
    #dbg_value(i32 poison, !20, !DIExpression(), !28)
  %7 = add nuw nsw i32 %6, 1, !dbg !40
    #dbg_value(i32 %7, !21, !DIExpression(), !30)
    #dbg_value(i32 poison, !20, !DIExpression(DW_OP_plus_uconst, 3, DW_OP_stack_value), !28)
    #dbg_value(i32 %h1, !19, !DIExpression(), !28)
  %8 = icmp eq i32 %6, 0, !dbg !41
  br i1 %8, label %5, label %1, !dbg !31, !llvm.loop !42
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !46 {
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !47
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !47
    #dbg_value(i32 %h, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !49)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !50
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !50
    #dbg_value(i32 %h1, !19, !DIExpression(), !49)
    #dbg_value(i32 0, !20, !DIExpression(), !49)
    #dbg_value(i32 0, !21, !DIExpression(), !51)
  br label %1, !dbg !52

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %3, %1 ]
    #dbg_value(i32 %2, !21, !DIExpression(), !51)
    #dbg_value(i32 poison, !20, !DIExpression(), !49)
    #dbg_value(i32 %h1, !19, !DIExpression(), !49)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 3.000000e-01), !dbg !53
    #dbg_value(i32 %h1, !19, !DIExpression(), !49)
    #dbg_value(i32 poison, !20, !DIExpression(), !49)
    #dbg_value(i32 poison, !20, !DIExpression(), !49)
  %3 = add nuw nsw i32 %2, 1, !dbg !54
    #dbg_value(i32 %3, !21, !DIExpression(), !51)
    #dbg_value(i32 poison, !20, !DIExpression(DW_OP_plus_uconst, 3, DW_OP_stack_value), !49)
    #dbg_value(i32 %h1, !19, !DIExpression(), !49)
  %4 = icmp eq i32 %2, 0, !dbg !55
  br i1 %4, label %1, label %5, !dbg !52, !llvm.loop !56

5:                                                ; preds = %1
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !58
  %6 = add nsw i32 %m, 6, !dbg !59
  %m2 = call i1 @cqrt_measure_i1(i32 %h), !dbg !60
  %7 = zext i1 %m2 to i32, !dbg !60
  %8 = add nsw i32 %6, %7, !dbg !61
  ret i32 %8, !dbg !62
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
!8 = !DIFile(filename: "w2e8_inner_classical_loop.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "6288ad51de85219b6fab2863d08dfb7a")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2e8_inner_classical_loop.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "6288ad51de85219b6fab2863d08dfb7a")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21, !23}
!18 = !DILocalVariable(name: "b", scope: !12, file: !13, line: 4, type: !10)
!19 = !DILocalVariable(name: "r", scope: !12, file: !13, line: 5, type: !16)
!20 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 6, type: !16)
!21 = !DILocalVariable(name: "k", scope: !22, file: !13, line: 7, type: !16)
!22 = distinct !DILexicalBlock(scope: !12, file: !13, line: 7, column: 5)
!23 = !DILocalVariable(name: "j", scope: !24, file: !13, line: 9, type: !16)
!24 = distinct !DILexicalBlock(scope: !25, file: !13, line: 9, column: 9)
!25 = distinct !DILexicalBlock(scope: !26, file: !13, line: 7, column: 33)
!26 = distinct !DILexicalBlock(scope: !22, file: !13, line: 7, column: 5)
!27 = !DILocation(line: 4, column: 14, scope: !12)
!28 = !DILocation(line: 0, scope: !12)
!29 = !DILocation(line: 5, column: 14, scope: !12)
!30 = !DILocation(line: 0, scope: !22)
!31 = !DILocation(line: 7, column: 5, scope: !22)
!32 = !DILocation(line: 11, column: 16, scope: !12)
!33 = !DILocation(line: 11, column: 14, scope: !12)
!34 = !DILocation(line: 11, column: 32, scope: !12)
!35 = !DILocation(line: 11, column: 30, scope: !12)
!36 = !DILocation(line: 11, column: 5, scope: !12)
!37 = !DILocation(line: 8, column: 20, scope: !38)
!38 = distinct !DILexicalBlock(scope: !25, file: !13, line: 8, column: 13)
!39 = !DILocation(line: 0, scope: !24)
!40 = !DILocation(line: 7, column: 28, scope: !26)
!41 = !DILocation(line: 7, column: 23, scope: !26)
!42 = distinct !{!42, !31, !43, !44, !45}
!43 = !DILocation(line: 10, column: 5, scope: !22)
!44 = !{!"llvm.loop.mustprogress"}
!45 = !{!"llvm.loop.unroll.disable"}
!46 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 13, type: !14, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!47 = !DILocation(line: 4, column: 14, scope: !12, inlinedAt: !48)
!48 = distinct !DILocation(line: 13, column: 25, scope: !46)
!49 = !DILocation(line: 0, scope: !12, inlinedAt: !48)
!50 = !DILocation(line: 5, column: 14, scope: !12, inlinedAt: !48)
!51 = !DILocation(line: 0, scope: !22, inlinedAt: !48)
!52 = !DILocation(line: 7, column: 5, scope: !22, inlinedAt: !48)
!53 = !DILocation(line: 8, column: 20, scope: !38, inlinedAt: !48)
!54 = !DILocation(line: 7, column: 28, scope: !26, inlinedAt: !48)
!55 = !DILocation(line: 7, column: 23, scope: !26, inlinedAt: !48)
!56 = distinct !{!56, !52, !57, !44, !45}
!57 = !DILocation(line: 10, column: 5, scope: !22, inlinedAt: !48)
!58 = !DILocation(line: 11, column: 16, scope: !12, inlinedAt: !48)
!59 = !DILocation(line: 11, column: 14, scope: !12, inlinedAt: !48)
!60 = !DILocation(line: 11, column: 32, scope: !12, inlinedAt: !48)
!61 = !DILocation(line: 11, column: 30, scope: !12, inlinedAt: !48)
!62 = !DILocation(line: 13, column: 18, scope: !46)
