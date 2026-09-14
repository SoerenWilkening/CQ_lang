; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/r6_pre_loop_measure.ll'
source_filename = "src/r6_pre_loop_measure.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !19
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !19
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !21
    #dbg_value(i32 %m, !16, !DIExpression(), !20)
    #dbg_value(i32 0, !17, !DIExpression(), !22)
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
  br label %3, !dbg !23

1:                                                ; preds = %3
  %m1 = call i32 @cqrt_measure_i32(i32 %h), !dbg !24
  %2 = add nsw i32 %m1, %m, !dbg !25
  ret i32 %2, !dbg !26

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %5, %3 ]
    #dbg_value(i32 %4, !17, !DIExpression(), !22)
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
  call void @cqrt_ry_i32(i32 %h, double 1.000000e-01), !dbg !27
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
  %5 = add nuw nsw i32 %4, 1, !dbg !30
    #dbg_value(i32 %5, !17, !DIExpression(), !22)
  %6 = icmp eq i32 %5, 3, !dbg !31
  br i1 %6, label %1, label %3, !dbg !23, !llvm.loop !32
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
!8 = !DIFile(filename: "src/r6_pre_loop_measure.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "450e66e33831dfdb0eb1870214be1838")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 3, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 3, column: 61)
!19 = !DILocation(line: 3, column: 23, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 3, column: 46, scope: !10)
!22 = !DILocation(line: 0, scope: !18)
!23 = !DILocation(line: 3, column: 61, scope: !18)
!24 = !DILocation(line: 3, column: 113, scope: !10)
!25 = !DILocation(line: 3, column: 112, scope: !10)
!26 = !DILocation(line: 3, column: 104, scope: !10)
!27 = !DILocation(line: 3, column: 85, scope: !28)
!28 = distinct !DILexicalBlock(scope: !29, file: !8, line: 3, column: 81)
!29 = distinct !DILexicalBlock(scope: !18, file: !8, line: 3, column: 61)
!30 = !DILocation(line: 3, column: 78, scope: !29)
!31 = !DILocation(line: 3, column: 74, scope: !29)
!32 = distinct !{!32, !23, !33, !34, !35}
!33 = !DILocation(line: 3, column: 102, scope: !18)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.unroll.disable"}
