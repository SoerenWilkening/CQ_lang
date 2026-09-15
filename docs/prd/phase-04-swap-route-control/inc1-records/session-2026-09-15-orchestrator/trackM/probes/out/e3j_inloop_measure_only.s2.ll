; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/out/e3j_inloop_measure_only.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3j_inloop_measure_only.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !19
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !19
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
  br label %2, !dbg !22

1:                                                ; preds = %2
  ret i32 %5, !dbg !23

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %6, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %5, %2 ]
    #dbg_value(i32 %3, !17, !DIExpression(), !21)
    #dbg_value(i32 %4, !16, !DIExpression(), !20)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !24
  %5 = add nsw i32 %m, %4, !dbg !27
    #dbg_value(i32 %5, !16, !DIExpression(), !20)
  %6 = add nuw nsw i32 %3, 1, !dbg !28
    #dbg_value(i32 %6, !17, !DIExpression(), !21)
  %7 = icmp eq i32 %6, 3, !dbg !29
  br i1 %7, label %1, label %2, !dbg !22, !llvm.loop !30
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3j_inloop_measure_only.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "1fd83de580a3e3aee66d50ab84f0e894")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 5, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 6, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 3)
!19 = !DILocation(line: 5, column: 23, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 6, column: 3, scope: !18)
!23 = !DILocation(line: 6, column: 45, scope: !10)
!24 = !DILocation(line: 6, column: 28, scope: !25)
!25 = distinct !DILexicalBlock(scope: !26, file: !8, line: 6, column: 23)
!26 = distinct !DILexicalBlock(scope: !18, file: !8, line: 6, column: 3)
!27 = !DILocation(line: 6, column: 26, scope: !25)
!28 = !DILocation(line: 6, column: 20, scope: !26)
!29 = !DILocation(line: 6, column: 16, scope: !26)
!30 = distinct !{!30, !22, !31, !32, !33}
!31 = !DILocation(line: 6, column: 43, scope: !18)
!32 = !{!"llvm.loop.mustprogress"}
!33 = !{!"llvm.loop.unroll.disable"}
