; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3o_postmeasure_store.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3o_postmeasure_store.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4, !dbg !0

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !14 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !20
    #dbg_value(i32 %1, !18, !DIExpression(), !21)
  %2 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !22
    #dbg_value(i32 %2, !19, !DIExpression(), !21)
  store i32 %1, ptr @g, align 4, !dbg !23, !tbaa !24
  %3 = add nsw i32 %2, %1, !dbg !28
  ret i32 %3, !dbg !29
}

declare !dbg !30 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !35 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!6, !7, !8, !9, !10, !11, !12}
!llvm.dbg.cu = !{!2}
!llvm.ident = !{!13}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(name: "g", scope: !2, file: !3, line: 4, type: !5, isLocal: false, isDefinition: true)
!2 = distinct !DICompileUnit(language: DW_LANG_C11, file: !3, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, globals: !4, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!3 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/src/e3o_postmeasure_store.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "f01be3f3096f9c2a95f6fb817c194aa8")
!4 = !{!0}
!5 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!6 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!7 = !{i32 7, !"Dwarf Version", i32 5}
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !{i32 1, !"wchar_size", i32 4}
!10 = !{i32 8, !"PIC Level", i32 2}
!11 = !{i32 7, !"uwtable", i32 2}
!12 = !{i32 7, !"frame-pointer", i32 2}
!13 = !{!"Homebrew clang version 19.1.7"}
!14 = distinct !DISubprogram(name: "main", scope: !3, file: !3, line: 5, type: !15, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !17)
!15 = !DISubroutineType(types: !16)
!16 = !{!5}
!17 = !{!18, !19}
!18 = !DILocalVariable(name: "q", scope: !14, file: !3, line: 5, type: !5)
!19 = !DILocalVariable(name: "m", scope: !14, file: !3, line: 5, type: !5)
!20 = !DILocation(line: 5, column: 23, scope: !14)
!21 = !DILocation(line: 0, scope: !14)
!22 = !DILocation(line: 5, column: 46, scope: !14)
!23 = !DILocation(line: 5, column: 62, scope: !14)
!24 = !{!25, !25, i64 0}
!25 = !{!"int", !26, i64 0}
!26 = !{!"omnipotent char", !27, i64 0}
!27 = !{!"Simple C/C++ TBAA"}
!28 = !DILocation(line: 5, column: 74, scope: !14)
!29 = !DILocation(line: 5, column: 66, scope: !14)
!30 = !DISubprogram(name: "cq_theta_si32", scope: !31, file: !31, line: 38, type: !32, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!31 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!32 = !DISubroutineType(types: !33)
!33 = !{!5, !5, !34}
!34 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!35 = !DISubprogram(name: "cq_measure_si32", scope: !31, file: !31, line: 83, type: !36, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!36 = !DISubroutineType(types: !37)
!37 = !{!5, !5}
