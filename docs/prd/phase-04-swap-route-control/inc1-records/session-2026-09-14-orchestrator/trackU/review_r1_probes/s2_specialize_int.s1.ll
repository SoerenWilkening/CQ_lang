; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/s2_specialize_int.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/s2_specialize_int.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call fastcc i32 @helper(), !dbg !17
    #dbg_value(i32 %1, !16, !DIExpression(), !18)
  %2 = tail call i32 @cq_measure_si32(i32 noundef %1) #3, !dbg !19
  ret i32 %2, !dbg !20
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc range(i32 -2147483645, -2147483648) i32 @helper() unnamed_addr #1 !dbg !21 {
    #dbg_value(i32 3, !25, !DIExpression(), !27)
  %1 = tail call i32 @cq_theta_si32(i32 noundef undef, double noundef 5.000000e-01) #3, !dbg !28
    #dbg_value(i32 %1, !26, !DIExpression(), !27)
  %2 = add nsw i32 %1, 3, !dbg !29
  ret i32 %2, !dbg !30
}

declare !dbg !31 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare !dbg !34 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/s2_specialize_int.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "9231ef082c703d4ee91f813da18e573f")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 7, type: !12, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/s2_specialize_int.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "9231ef082c703d4ee91f813da18e573f")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16}
!16 = !DILocalVariable(name: "r", scope: !10, file: !11, line: 8, type: !14)
!17 = !DILocation(line: 8, column: 13, scope: !10)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 9, column: 12, scope: !10)
!20 = !DILocation(line: 9, column: 5, scope: !10)
!21 = distinct !DISubprogram(name: "helper", scope: !11, file: !11, line: 2, type: !22, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !24)
!22 = !DISubroutineType(cc: DW_CC_nocall, types: !23)
!23 = !{!14, !14}
!24 = !{!25, !26}
!25 = !DILocalVariable(name: "k", arg: 1, scope: !21, file: !11, line: 2, type: !14)
!26 = !DILocalVariable(name: "b", scope: !21, file: !11, line: 3, type: !14)
!27 = !DILocation(line: 0, scope: !21)
!28 = !DILocation(line: 4, column: 9, scope: !21)
!29 = !DILocation(line: 5, column: 14, scope: !21)
!30 = !DILocation(line: 5, column: 5, scope: !21)
!31 = !DISubprogram(name: "cq_measure_si32", scope: !32, file: !32, line: 83, type: !33, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!32 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!33 = !DISubroutineType(types: !23)
!34 = !DISubprogram(name: "cq_theta_si32", scope: !32, file: !32, line: 38, type: !35, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!35 = !DISubroutineType(types: !36)
!36 = !{!14, !14, !37}
!37 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
