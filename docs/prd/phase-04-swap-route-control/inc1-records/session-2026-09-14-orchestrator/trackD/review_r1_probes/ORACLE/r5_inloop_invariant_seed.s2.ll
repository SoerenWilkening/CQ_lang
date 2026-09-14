; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes/s1/r5_inloop_invariant_seed.ll'
source_filename = "src/r5_inloop_invariant_seed.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !22
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !22
    #dbg_value(i32 %h, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
  br label %2, !dbg !25

1:                                                ; preds = %2
  ret i32 %5, !dbg !26

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %5, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %6, %2 ]
    #dbg_value(i32 %3, !16, !DIExpression(), !23)
    #dbg_value(i32 %4, !17, !DIExpression(), !24)
  call void @cqrt_ry_i32(i32 %h, double 1.000000e-01), !dbg !27
    #dbg_value(i32 %h, !19, !DIExpression(), !28)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !29
  %5 = add nsw i32 %m, %3, !dbg !30
    #dbg_value(i32 %5, !16, !DIExpression(), !23)
  %6 = add nuw nsw i32 %4, 1, !dbg !31
    #dbg_value(i32 %6, !17, !DIExpression(), !24)
  %7 = icmp eq i32 %6, 3, !dbg !32
  br i1 %7, label %1, label %2, !dbg !25, !llvm.loop !33
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
!8 = !DIFile(filename: "src/r5_inloop_invariant_seed.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes", checksumkind: CSK_MD5, checksum: "c8c317a2fc132655b99e0c429d888490")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 4, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 49)
!19 = !DILocalVariable(name: "b", scope: !20, file: !8, line: 4, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 4, column: 69)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 4, column: 49)
!22 = !DILocation(line: 4, column: 23, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 4, column: 49, scope: !18)
!26 = !DILocation(line: 4, column: 114, scope: !10)
!27 = !DILocation(line: 4, column: 77, scope: !20)
!28 = !DILocation(line: 0, scope: !20)
!29 = !DILocation(line: 4, column: 97, scope: !20)
!30 = !DILocation(line: 4, column: 95, scope: !20)
!31 = !DILocation(line: 4, column: 66, scope: !21)
!32 = !DILocation(line: 4, column: 62, scope: !21)
!33 = distinct !{!33, !25, !34, !35, !36}
!34 = !DILocation(line: 4, column: 112, scope: !18)
!35 = !{!"llvm.loop.mustprogress"}
!36 = !{!"llvm.loop.unroll.disable"}
