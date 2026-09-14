; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p1_inloop_prep.stage1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p1_inloop_prep.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !16, !DIExpression(), !24)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
    #dbg_value(i32 0, !18, !DIExpression(), !25)
  br label %2, !dbg !26

1:                                                ; preds = %2
  ret i32 %6, !dbg !27

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %7, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %6, %2 ]
    #dbg_value(i32 %3, !18, !DIExpression(), !25)
    #dbg_value(i32 %4, !17, !DIExpression(), !24)
    #dbg_value(i32 poison, !16, !DIExpression(), !24)
    #dbg_value(i8 0, !20, !DIExpression(), !28)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !29
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !29
    #dbg_value(i32 %h, !20, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !28)
    #dbg_value(i8 poison, !20, !DIExpression(), !28)
  %m = call i1 @cqrt_measure_i1(i32 %h), !dbg !32
  %5 = zext i1 %m to i32, !dbg !32
  %6 = add nuw nsw i32 %4, %5, !dbg !33
    #dbg_value(i32 %6, !17, !DIExpression(), !24)
    #dbg_value(i32 poison, !16, !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value), !24)
  %7 = add nuw nsw i32 %3, 1, !dbg !34
    #dbg_value(i32 %7, !18, !DIExpression(), !25)
  %8 = icmp eq i32 %7, 3, !dbg !35
  br i1 %8, label %1, label %2, !dbg !26, !llvm.loop !36
}

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare i1 @cqrt_measure_i1(i32)

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p1_inloop_prep.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "9737073940f58a393cd06649316718d8")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 6, type: !12, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p1_inloop_prep.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "9737073940f58a393cd06649316718d8")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !18, !20}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 7, type: !14)
!17 = !DILocalVariable(name: "s", scope: !10, file: !11, line: 8, type: !14)
!18 = !DILocalVariable(name: "i", scope: !19, file: !11, line: 9, type: !14)
!19 = distinct !DILexicalBlock(scope: !10, file: !11, line: 9, column: 5)
!20 = !DILocalVariable(name: "b", scope: !21, file: !11, line: 10, type: !23)
!21 = distinct !DILexicalBlock(scope: !22, file: !11, line: 9, column: 33)
!22 = distinct !DILexicalBlock(scope: !19, file: !11, line: 9, column: 5)
!23 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 0, scope: !19)
!26 = !DILocation(line: 9, column: 5, scope: !19)
!27 = !DILocation(line: 15, column: 5, scope: !10)
!28 = !DILocation(line: 0, scope: !21)
!29 = !DILocation(line: 11, column: 27, scope: !30)
!30 = distinct !DILexicalBlock(scope: !31, file: !11, line: 11, column: 21)
!31 = distinct !DILexicalBlock(scope: !21, file: !11, line: 11, column: 13)
!32 = !DILocation(line: 12, column: 14, scope: !21)
!33 = !DILocation(line: 12, column: 11, scope: !21)
!34 = !DILocation(line: 9, column: 29, scope: !22)
!35 = !DILocation(line: 9, column: 23, scope: !22)
!36 = distinct !{!36, !26, !37, !38, !39}
!37 = !DILocation(line: 14, column: 5, scope: !19)
!38 = !{!"llvm.loop.mustprogress"}
!39 = !{!"llvm.loop.unroll.disable"}
