; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes/s1/r11_postloop_measure.ll'
source_filename = "src/r11_postloop_measure.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !18
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !18
    #dbg_value(i32 %h, !15, !DIExpression(), !19)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
  br label %2, !dbg !21

1:                                                ; preds = %2
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !22
  ret i32 %m, !dbg !23

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %4, %2 ]
    #dbg_value(i32 %3, !16, !DIExpression(), !20)
    #dbg_value(i32 %h, !15, !DIExpression(), !19)
  call void @cqrt_ry_i32(i32 %h, double 1.000000e-01), !dbg !24
    #dbg_value(i32 %h, !15, !DIExpression(), !19)
  %4 = add nuw nsw i32 %3, 1, !dbg !27
    #dbg_value(i32 %4, !16, !DIExpression(), !20)
  %5 = icmp eq i32 %4, 4, !dbg !28
  br i1 %5, label %1, label %2, !dbg !21, !llvm.loop !29
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
!8 = !DIFile(filename: "src/r11_postloop_measure.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r1_probes", checksumkind: CSK_MD5, checksum: "719bed01beef19982adc88542d78cfad")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "i", scope: !17, file: !8, line: 3, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 3, column: 40)
!18 = !DILocation(line: 3, column: 23, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 0, scope: !17)
!21 = !DILocation(line: 3, column: 40, scope: !17)
!22 = !DILocation(line: 3, column: 90, scope: !10)
!23 = !DILocation(line: 3, column: 83, scope: !10)
!24 = !DILocation(line: 3, column: 64, scope: !25)
!25 = distinct !DILexicalBlock(scope: !26, file: !8, line: 3, column: 60)
!26 = distinct !DILexicalBlock(scope: !17, file: !8, line: 3, column: 40)
!27 = !DILocation(line: 3, column: 57, scope: !26)
!28 = !DILocation(line: 3, column: 53, scope: !26)
!29 = distinct !{!29, !21, !30, !31, !32}
!30 = !DILocation(line: 3, column: 81, scope: !17)
!31 = !{!"llvm.loop.mustprogress"}
!32 = !{!"llvm.loop.unroll.disable"}
