; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/fve8_phi.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/fve8_phi.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !18)
  %h = call i32 @cqrt_alloc_i32(i32 3), !dbg !19
  call void @cqrt_ry_i32(i32 %h, double 4.000000e-01), !dbg !19
    #dbg_value(i32 %h, !16, !DIExpression(), !18)
    #dbg_value(i32 %h, !17, !DIExpression(), !18)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !20
  %m1 = call i32 @cqrt_measure_i32(i32 %h), !dbg !21
  %2 = add nsw i32 %m1, %m, !dbg !22
  ret i32 %2, !dbg !23
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !24 {
    #dbg_value(i32 2, !15, !DIExpression(), !27)
  %h = call i32 @cqrt_alloc_i32(i32 3), !dbg !29
  call void @cqrt_ry_i32(i32 %h, double 4.000000e-01), !dbg !29
    #dbg_value(i32 %h, !16, !DIExpression(), !27)
    #dbg_value(i32 %h, !17, !DIExpression(), !27)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !30
  %m1 = call i32 @cqrt_measure_i32(i32 %h), !dbg !31
  %1 = add nsw i32 %m1, %m, !dbg !32
  ret i32 %1, !dbg !33
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/fve8_phi.c", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang", checksumkind: CSK_MD5, checksum: "d18bc007cb7cc51dc87986a35b76db27")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 1, type: !11, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "k", arg: 1, scope: !10, file: !8, line: 1, type: !13)
!16 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 2, type: !13)
!17 = !DILocalVariable(name: "u", scope: !10, file: !8, line: 3, type: !13)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 2, column: 11, scope: !10)
!20 = !DILocation(line: 5, column: 10, scope: !10)
!21 = !DILocation(line: 5, column: 26, scope: !10)
!22 = !DILocation(line: 5, column: 24, scope: !10)
!23 = !DILocation(line: 5, column: 3, scope: !10)
!24 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 7, type: !25, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!25 = !DISubroutineType(types: !26)
!26 = !{!13}
!27 = !DILocation(line: 0, scope: !10, inlinedAt: !28)
!28 = distinct !DILocation(line: 7, column: 25, scope: !24)
!29 = !DILocation(line: 2, column: 11, scope: !10, inlinedAt: !28)
!30 = !DILocation(line: 5, column: 10, scope: !10, inlinedAt: !28)
!31 = !DILocation(line: 5, column: 26, scope: !10, inlinedAt: !28)
!32 = !DILocation(line: 5, column: 24, scope: !10, inlinedAt: !28)
!33 = !DILocation(line: 7, column: 18, scope: !24)
