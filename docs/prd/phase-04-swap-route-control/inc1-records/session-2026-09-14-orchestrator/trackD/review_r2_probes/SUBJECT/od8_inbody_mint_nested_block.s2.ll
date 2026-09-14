; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/od8_inbody_mint_nested_block.ll'
source_filename = "src/od8_inbody_mint_nested_block.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !24)
    #dbg_value(i32 0, !16, !DIExpression(), !25)
  br label %2, !dbg !26

1:                                                ; preds = %9
  ret i32 %10, !dbg !27

2:                                                ; preds = %9, %0
  %3 = phi i32 [ 0, %0 ], [ %10, %9 ]
  %4 = phi i32 [ 0, %0 ], [ %11, %9 ]
    #dbg_value(i32 %3, !15, !DIExpression(), !24)
    #dbg_value(i32 %4, !16, !DIExpression(), !25)
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !28
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !28
    #dbg_value(i32 %h, !18, !DIExpression(), !29)
  %5 = and i32 %4, 1, !dbg !30
  %6 = icmp eq i32 %5, 0, !dbg !30
  br i1 %6, label %9, label %7, !dbg !31

7:                                                ; preds = %2
  call void @cqrt_ry_i32(i32 %h, double 1.000000e-01), !dbg !32
    #dbg_value(i32 %h, !21, !DIExpression(), !33)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !34
  %8 = add nsw i32 %m, %3, !dbg !35
    #dbg_value(i32 %8, !15, !DIExpression(), !24)
  br label %9, !dbg !36

9:                                                ; preds = %7, %2
  %10 = phi i32 [ %8, %7 ], [ %3, %2 ], !dbg !24
    #dbg_value(i32 %10, !15, !DIExpression(), !24)
  %11 = add nuw nsw i32 %4, 1, !dbg !37
    #dbg_value(i32 %11, !16, !DIExpression(), !25)
  %12 = icmp eq i32 %11, 4, !dbg !38
  br i1 %12, label %1, label %2, !dbg !26, !llvm.loop !39
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
!8 = !DIFile(filename: "src/od8_inbody_mint_nested_block.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "798c5efc9f9bdf55bcfec6d90fef42ff")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18, !21}
!15 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "i", scope: !17, file: !8, line: 3, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 3, column: 26)
!18 = !DILocalVariable(name: "q", scope: !19, file: !8, line: 3, type: !13)
!19 = distinct !DILexicalBlock(scope: !20, file: !8, line: 3, column: 46)
!20 = distinct !DILexicalBlock(scope: !17, file: !8, line: 3, column: 26)
!21 = !DILocalVariable(name: "b", scope: !22, file: !8, line: 4, type: !13)
!22 = distinct !DILexicalBlock(scope: !23, file: !8, line: 4, column: 10)
!23 = distinct !DILexicalBlock(scope: !19, file: !8, line: 4, column: 6)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 0, scope: !17)
!26 = !DILocation(line: 3, column: 26, scope: !17)
!27 = !DILocation(line: 4, column: 57, scope: !10)
!28 = !DILocation(line: 3, column: 54, scope: !19)
!29 = !DILocation(line: 0, scope: !19)
!30 = !DILocation(line: 4, column: 7, scope: !23)
!31 = !DILocation(line: 4, column: 6, scope: !19)
!32 = !DILocation(line: 4, column: 18, scope: !22)
!33 = !DILocation(line: 0, scope: !22)
!34 = !DILocation(line: 4, column: 38, scope: !22)
!35 = !DILocation(line: 4, column: 36, scope: !22)
!36 = !DILocation(line: 4, column: 53, scope: !22)
!37 = !DILocation(line: 3, column: 43, scope: !20)
!38 = !DILocation(line: 3, column: 39, scope: !20)
!39 = distinct !{!39, !26, !40, !41, !42}
!40 = !DILocation(line: 4, column: 55, scope: !17)
!41 = !{!"llvm.loop.mustprogress"}
!42 = !{!"llvm.loop.unroll.disable"}
