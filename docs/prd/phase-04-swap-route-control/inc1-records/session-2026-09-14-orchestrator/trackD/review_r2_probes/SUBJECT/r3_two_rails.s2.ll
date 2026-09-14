; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes/s1/r3_two_rails.ll'
source_filename = "src/r3_two_rails.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 0), !dbg !19
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01), !dbg !19
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
  %h1 = call i32 @cqrt_alloc_i32(i32 1), !dbg !21
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !21
    #dbg_value(i32 %h1, !16, !DIExpression(), !20)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !22
    #dbg_value(i32 %h, !17, !DIExpression(), !20)
  call void @cqrt_ry_i32(i32 %h1, double 6.000000e-01), !dbg !23
    #dbg_value(i32 %h1, !18, !DIExpression(), !20)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !24
  %m2 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !25
  %1 = add nsw i32 %m2, %m, !dbg !26
  ret i32 %1, !dbg !27
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
!8 = !DIFile(filename: "src/r3_two_rails.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "890a202b07f778dd37d4872674e8b20d")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "q1", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "q2", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 3, type: !13)
!18 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 3, type: !13)
!19 = !DILocation(line: 3, column: 24, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 3, column: 48, scope: !10)
!22 = !DILocation(line: 3, column: 71, scope: !10)
!23 = !DILocation(line: 3, column: 95, scope: !10)
!24 = !DILocation(line: 3, column: 120, scope: !10)
!25 = !DILocation(line: 3, column: 134, scope: !10)
!26 = !DILocation(line: 3, column: 133, scope: !10)
!27 = !DILocation(line: 3, column: 113, scope: !10)
