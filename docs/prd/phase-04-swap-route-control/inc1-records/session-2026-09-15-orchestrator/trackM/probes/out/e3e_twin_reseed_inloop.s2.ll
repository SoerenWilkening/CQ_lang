; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/out/e3e_twin_reseed_inloop.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3e_twin_reseed_inloop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !23
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !23
    #dbg_value(i32 %h, !15, !DIExpression(), !24)
    #dbg_value(i32 0, !16, !DIExpression(), !24)
    #dbg_value(i32 0, !17, !DIExpression(), !25)
  br label %2, !dbg !26

1:                                                ; preds = %2
  ret i32 %5, !dbg !27

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %5, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %6, %2 ]
    #dbg_value(i32 %3, !16, !DIExpression(), !24)
    #dbg_value(i32 %4, !17, !DIExpression(), !25)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !28
    #dbg_value(i32 %m, !19, !DIExpression(), !29)
  %h1 = call i32 @cqrt_alloc_i32(i32 %m), !dbg !30
  call void @cqrt_ry_i32(i32 %h1, double 5.000000e-01), !dbg !30
    #dbg_value(i32 %h1, !22, !DIExpression(), !29)
  %m2 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !31
  %5 = add nsw i32 %m2, %3, !dbg !32
    #dbg_value(i32 %5, !16, !DIExpression(), !24)
  %6 = add nuw nsw i32 %4, 1, !dbg !33
    #dbg_value(i32 %6, !17, !DIExpression(), !25)
  %7 = icmp eq i32 %6, 3, !dbg !34
  br i1 %7, label %1, label %2, !dbg !26, !llvm.loop !35
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3e_twin_reseed_inloop.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "edcabbe5f9b26573b6f8a26d16004344")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19, !22}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 3, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 3, column: 49)
!19 = !DILocalVariable(name: "m", scope: !20, file: !8, line: 3, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 3, column: 69)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 3, column: 49)
!22 = !DILocalVariable(name: "a", scope: !20, file: !8, line: 3, type: !13)
!23 = !DILocation(line: 3, column: 23, scope: !10)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 0, scope: !18)
!26 = !DILocation(line: 3, column: 49, scope: !18)
!27 = !DILocation(line: 3, column: 134, scope: !10)
!28 = !DILocation(line: 3, column: 77, scope: !20)
!29 = !DILocation(line: 0, scope: !20)
!30 = !DILocation(line: 3, column: 98, scope: !20)
!31 = !DILocation(line: 3, column: 118, scope: !20)
!32 = !DILocation(line: 3, column: 116, scope: !20)
!33 = !DILocation(line: 3, column: 66, scope: !21)
!34 = !DILocation(line: 3, column: 62, scope: !21)
!35 = distinct !{!35, !26, !36, !37, !38}
!36 = !DILocation(line: 3, column: 132, scope: !18)
!37 = !{!"llvm.loop.mustprogress"}
!38 = !{!"llvm.loop.unroll.disable"}
