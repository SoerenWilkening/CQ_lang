; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.NGUksmBfAT/s1.ll'
source_filename = "./w2a_twoloop_passonly.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
    #dbg_value(i32 0, !18, !DIExpression(), !31)
    #dbg_value(i32 0, !19, !DIExpression(), !32)
  br label %1, !dbg !33

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %6, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %7, %1 ]
    #dbg_value(i32 %2, !18, !DIExpression(), !31)
    #dbg_value(i32 %3, !19, !DIExpression(), !32)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !34
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !34
    #dbg_value(i32 %h, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !35)
  %h2 = call i32 @cqrt_alloc_i32(i32 7), !dbg !36
  call void @cqrt_ry_i32(i32 %h2, double 2.500000e-01), !dbg !36
    #dbg_value(i32 %h2, !24, !DIExpression(), !35)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h2, double 2.000000e-01), !dbg !37
    #dbg_value(i32 %h2, !24, !DIExpression(), !35)
  %m = call i32 @cqrt_measure_i32(i32 %h2), !dbg !39
  %m4 = call i1 @cqrt_measure_i1(i32 %h), !dbg !40
  %4 = zext i1 %m4 to i32, !dbg !40
  %5 = add i32 %m, %2, !dbg !41
  %6 = add i32 %5, %4, !dbg !42
    #dbg_value(i32 %6, !18, !DIExpression(), !31)
  %7 = add nuw nsw i32 %3, 1, !dbg !43
    #dbg_value(i32 %7, !19, !DIExpression(), !32)
  %8 = icmp eq i32 %3, 0, !dbg !44
  br i1 %8, label %1, label %10, !dbg !33, !llvm.loop !45

9:                                                ; preds = %10
  ret i32 %15, !dbg !49

10:                                               ; preds = %10, %1
  %11 = phi i32 [ %15, %10 ], [ %6, %1 ]
  %12 = phi i32 [ %16, %10 ], [ 0, %1 ]
    #dbg_value(i32 %11, !18, !DIExpression(), !31)
    #dbg_value(i32 %12, !25, !DIExpression(), !50)
  %h1 = call i32 @cqrt_alloc_i1(i1 false), !dbg !51
  call void @cqrt_ry_i1(i32 %h1, double 6.000000e-01), !dbg !51
    #dbg_value(i32 %h1, !27, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !52)
  %h3 = call i32 @cqrt_alloc_i32(i32 9), !dbg !53
  call void @cqrt_ry_i32(i32 %h3, double 3.500000e-01), !dbg !53
    #dbg_value(i32 %h3, !30, !DIExpression(), !52)
  call void @cqrt_ry_i32_controlled(i32 %h1, i32 %h3, double 3.000000e-01), !dbg !54
    #dbg_value(i32 %h3, !30, !DIExpression(), !52)
  %m5 = call i32 @cqrt_measure_i32(i32 %h3), !dbg !56
  %m6 = call i1 @cqrt_measure_i1(i32 %h1), !dbg !57
  %13 = zext i1 %m6 to i32, !dbg !57
  %14 = add i32 %m5, %11, !dbg !58
  %15 = add i32 %14, %13, !dbg !59
    #dbg_value(i32 %15, !18, !DIExpression(), !31)
  %16 = add nuw nsw i32 %12, 1, !dbg !60
    #dbg_value(i32 %16, !25, !DIExpression(), !50)
  %17 = icmp eq i32 %12, 0, !dbg !61
  br i1 %17, label %10, label %9, !dbg !62, !llvm.loop !63
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !65 {
  %1 = tail call i32 @slice(), !dbg !66
  ret i32 %1, !dbg !67
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
!8 = !DIFile(filename: "w2a_twoloop_passonly.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "85338d74a16711bcb4a11a6a29f3bbd6")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 4, type: !14, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2a_twoloop_passonly.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "85338d74a16711bcb4a11a6a29f3bbd6")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !21, !24, !25, !27, !30}
!18 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 5, type: !16)
!19 = !DILocalVariable(name: "k", scope: !20, file: !13, line: 6, type: !16)
!20 = distinct !DILexicalBlock(scope: !12, file: !13, line: 6, column: 5)
!21 = !DILocalVariable(name: "t", scope: !22, file: !13, line: 7, type: !10)
!22 = distinct !DILexicalBlock(scope: !23, file: !13, line: 6, column: 33)
!23 = distinct !DILexicalBlock(scope: !20, file: !13, line: 6, column: 5)
!24 = !DILocalVariable(name: "r", scope: !22, file: !13, line: 8, type: !16)
!25 = !DILocalVariable(name: "k", scope: !26, file: !13, line: 12, type: !16)
!26 = distinct !DILexicalBlock(scope: !12, file: !13, line: 12, column: 5)
!27 = !DILocalVariable(name: "t2", scope: !28, file: !13, line: 13, type: !10)
!28 = distinct !DILexicalBlock(scope: !29, file: !13, line: 12, column: 33)
!29 = distinct !DILexicalBlock(scope: !26, file: !13, line: 12, column: 5)
!30 = !DILocalVariable(name: "r2", scope: !28, file: !13, line: 14, type: !16)
!31 = !DILocation(line: 0, scope: !12)
!32 = !DILocation(line: 0, scope: !20)
!33 = !DILocation(line: 6, column: 5, scope: !20)
!34 = !DILocation(line: 7, column: 18, scope: !22)
!35 = !DILocation(line: 0, scope: !22)
!36 = !DILocation(line: 8, column: 17, scope: !22)
!37 = !DILocation(line: 9, column: 20, scope: !38)
!38 = distinct !DILexicalBlock(scope: !22, file: !13, line: 9, column: 13)
!39 = !DILocation(line: 10, column: 14, scope: !22)
!40 = !DILocation(line: 10, column: 30, scope: !22)
!41 = !DILocation(line: 10, column: 28, scope: !22)
!42 = !DILocation(line: 10, column: 11, scope: !22)
!43 = !DILocation(line: 6, column: 28, scope: !23)
!44 = !DILocation(line: 6, column: 23, scope: !23)
!45 = distinct !{!45, !33, !46, !47, !48}
!46 = !DILocation(line: 11, column: 5, scope: !20)
!47 = !{!"llvm.loop.mustprogress"}
!48 = !{!"llvm.loop.unroll.disable"}
!49 = !DILocation(line: 18, column: 5, scope: !12)
!50 = !DILocation(line: 0, scope: !26)
!51 = !DILocation(line: 13, column: 19, scope: !28)
!52 = !DILocation(line: 0, scope: !28)
!53 = !DILocation(line: 14, column: 18, scope: !28)
!54 = !DILocation(line: 15, column: 22, scope: !55)
!55 = distinct !DILexicalBlock(scope: !28, file: !13, line: 15, column: 13)
!56 = !DILocation(line: 16, column: 14, scope: !28)
!57 = !DILocation(line: 16, column: 31, scope: !28)
!58 = !DILocation(line: 16, column: 29, scope: !28)
!59 = !DILocation(line: 16, column: 11, scope: !28)
!60 = !DILocation(line: 12, column: 28, scope: !29)
!61 = !DILocation(line: 12, column: 23, scope: !29)
!62 = !DILocation(line: 12, column: 5, scope: !26)
!63 = distinct !{!63, !62, !64, !47, !48}
!64 = !DILocation(line: 17, column: 5, scope: !26)
!65 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 20, type: !14, scopeLine: 20, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!66 = !DILocation(line: 20, column: 25, scope: !65)
!67 = !DILocation(line: 20, column: 18, scope: !65)
