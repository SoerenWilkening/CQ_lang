; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/ob1_reader_runs_once_in_loop.ll'
source_filename = "src/ob1_reader_runs_once_in_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !24
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !24
    #dbg_value(i32 %h, !15, !DIExpression(), !25)
    #dbg_value(i32 0, !16, !DIExpression(), !25)
    #dbg_value(i32 0, !17, !DIExpression(), !26)
  br label %2, !dbg !27

1:                                                ; preds = %7
  ret i32 %9, !dbg !28

2:                                                ; preds = %7, %0
  %3 = phi i32 [ 0, %0 ], [ %9, %7 ]
  %4 = phi i32 [ 0, %0 ], [ %10, %7 ]
    #dbg_value(i32 %3, !16, !DIExpression(), !25)
    #dbg_value(i32 %4, !17, !DIExpression(), !26)
  %5 = icmp eq i32 %4, 0, !dbg !29
  br i1 %5, label %6, label %7, !dbg !30

6:                                                ; preds = %2
  call void @cqrt_ry_i32(i32 %h, double 1.000000e-01), !dbg !31
    #dbg_value(i32 %h, !19, !DIExpression(), !32)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !33
    #dbg_value(!DIArgList(i32 %3, i32 %m), !16, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !25)
  br label %7, !dbg !34

7:                                                ; preds = %6, %2
  %8 = phi i32 [ %m, %6 ], [ 1, %2 ]
  %9 = add nsw i32 %8, %3, !dbg !35
    #dbg_value(i32 %9, !16, !DIExpression(), !25)
  %10 = add nuw nsw i32 %4, 1, !dbg !36
    #dbg_value(i32 %10, !17, !DIExpression(), !26)
  %11 = icmp eq i32 %10, 3, !dbg !37
  br i1 %11, label %1, label %2, !dbg !27, !llvm.loop !38
}

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
!8 = !DIFile(filename: "src/ob1_reader_runs_once_in_loop.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "e3090d018b295390889d314f8f9c7847")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 6, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 7, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 7, column: 3)
!19 = !DILocalVariable(name: "b", scope: !20, file: !8, line: 7, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 7, column: 33)
!21 = distinct !DILexicalBlock(scope: !22, file: !8, line: 7, column: 28)
!22 = distinct !DILexicalBlock(scope: !23, file: !8, line: 7, column: 23)
!23 = distinct !DILexicalBlock(scope: !18, file: !8, line: 7, column: 3)
!24 = !DILocation(line: 6, column: 23, scope: !10)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 0, scope: !18)
!27 = !DILocation(line: 7, column: 3, scope: !18)
!28 = !DILocation(line: 8, column: 3, scope: !10)
!29 = !DILocation(line: 7, column: 29, scope: !21)
!30 = !DILocation(line: 7, column: 28, scope: !22)
!31 = !DILocation(line: 7, column: 41, scope: !20)
!32 = !DILocation(line: 0, scope: !20)
!33 = !DILocation(line: 7, column: 61, scope: !20)
!34 = !DILocation(line: 7, column: 76, scope: !20)
!35 = !DILocation(line: 7, scope: !21)
!36 = !DILocation(line: 7, column: 20, scope: !23)
!37 = !DILocation(line: 7, column: 16, scope: !23)
!38 = distinct !{!38, !27, !39, !40, !41}
!39 = !DILocation(line: 7, column: 89, scope: !18)
!40 = !{!"llvm.loop.mustprogress"}
!41 = !{!"llvm.loop.unroll.disable"}
