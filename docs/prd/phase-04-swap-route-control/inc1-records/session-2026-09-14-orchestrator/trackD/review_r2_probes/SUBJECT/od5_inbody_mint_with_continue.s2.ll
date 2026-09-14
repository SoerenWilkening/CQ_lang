; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/od5_inbody_mint_with_continue.ll'
source_filename = "src/od5_inbody_mint_with_continue.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !22)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
  br label %2, !dbg !24

1:                                                ; preds = %11
  ret i32 %12, !dbg !25

2:                                                ; preds = %11, %0
  %3 = phi i32 [ 0, %0 ], [ %12, %11 ]
  %4 = phi i32 [ 0, %0 ], [ %13, %11 ]
    #dbg_value(i32 %3, !15, !DIExpression(), !22)
    #dbg_value(i32 %4, !16, !DIExpression(), !23)
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !26
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !26
    #dbg_value(i32 %h, !18, !DIExpression(), !27)
  %5 = and i32 %4, 1, !dbg !28
  %6 = icmp eq i32 %5, 0, !dbg !28
  br i1 %6, label %9, label %7, !dbg !30

7:                                                ; preds = %2
  %8 = add nsw i32 %3, 1, !dbg !31
    #dbg_value(i32 %8, !15, !DIExpression(), !22)
  br label %11, !dbg !33

9:                                                ; preds = %2
  call void @cqrt_ry_i32(i32 %h, double 1.000000e-01), !dbg !34
    #dbg_value(i32 %h, !21, !DIExpression(), !27)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !35
  %10 = add nsw i32 %m, %3, !dbg !36
    #dbg_value(i32 %10, !15, !DIExpression(), !22)
  br label %11, !dbg !37

11:                                               ; preds = %9, %7
  %12 = phi i32 [ %8, %7 ], [ %10, %9 ], !dbg !27
    #dbg_value(i32 %12, !15, !DIExpression(), !22)
  %13 = add nuw nsw i32 %4, 1, !dbg !38
    #dbg_value(i32 %13, !16, !DIExpression(), !23)
  %14 = icmp eq i32 %13, 4, !dbg !39
  br i1 %14, label %1, label %2, !dbg !24, !llvm.loop !40
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
!8 = !DIFile(filename: "src/od5_inbody_mint_with_continue.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "335b9feef305d20d4a8b950e08b28f6e")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18, !21}
!15 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "i", scope: !17, file: !8, line: 4, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 26)
!18 = !DILocalVariable(name: "q", scope: !19, file: !8, line: 4, type: !13)
!19 = distinct !DILexicalBlock(scope: !20, file: !8, line: 4, column: 46)
!20 = distinct !DILexicalBlock(scope: !17, file: !8, line: 4, column: 26)
!21 = !DILocalVariable(name: "b", scope: !19, file: !8, line: 5, type: !13)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 0, scope: !17)
!24 = !DILocation(line: 4, column: 26, scope: !17)
!25 = !DILocation(line: 5, column: 56, scope: !10)
!26 = !DILocation(line: 4, column: 54, scope: !19)
!27 = !DILocation(line: 0, scope: !19)
!28 = !DILocation(line: 4, column: 75, scope: !29)
!29 = distinct !DILexicalBlock(scope: !19, file: !8, line: 4, column: 74)
!30 = !DILocation(line: 4, column: 74, scope: !19)
!31 = !DILocation(line: 4, column: 81, scope: !32)
!32 = distinct !DILexicalBlock(scope: !29, file: !8, line: 4, column: 78)
!33 = !DILocation(line: 4, column: 86, scope: !32)
!34 = !DILocation(line: 5, column: 9, scope: !19)
!35 = !DILocation(line: 5, column: 29, scope: !19)
!36 = !DILocation(line: 5, column: 27, scope: !19)
!37 = !DILocation(line: 5, column: 44, scope: !20)
!38 = !DILocation(line: 4, column: 43, scope: !20)
!39 = !DILocation(line: 4, column: 39, scope: !20)
!40 = distinct !{!40, !24, !41, !42, !43}
!41 = !DILocation(line: 5, column: 44, scope: !17)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
