; ModuleID = 'src/e2u_undef_measure_guards_quantum.c'
source_filename = "src/e2u_undef_measure_guards_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_measure_si32(i32 noundef undef) #2, !dbg !18
    #dbg_value(i32 %1, !16, !DIExpression(), !19)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !20
    #dbg_value(i32 %2, !17, !DIExpression(), !19)
  %3 = icmp eq i32 %1, 0, !dbg !21
  br i1 %3, label %6, label %4, !dbg !23

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #2, !dbg !24
    #dbg_value(i32 %5, !17, !DIExpression(), !19)
  br label %6, !dbg !25

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ], !dbg !26
    #dbg_value(i32 %7, !17, !DIExpression(), !19)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !27
  ret i32 %8, !dbg !28
}

declare !dbg !29 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare !dbg !33 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

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
!8 = !DIFile(filename: "src/e2u_undef_measure_guards_quantum.c", directory: "/Users/sorenwilkening/Desktop/CQ_E2/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackE2/probes", checksumkind: CSK_MD5, checksum: "eedeba1d3bcf79e1e844d65f1ced6724")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "u", scope: !10, file: !8, line: 5, type: !13)
!16 = !DILocalVariable(name: "m", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 5, type: !13)
!18 = !DILocation(line: 5, column: 32, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 5, column: 55, scope: !10)
!21 = !DILocation(line: 5, column: 77, scope: !22)
!22 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 77)
!23 = !DILocation(line: 5, column: 77, scope: !10)
!24 = !DILocation(line: 5, column: 84, scope: !22)
!25 = !DILocation(line: 5, column: 80, scope: !22)
!26 = !DILocation(line: 5, scope: !10)
!27 = !DILocation(line: 5, column: 109, scope: !10)
!28 = !DILocation(line: 5, column: 102, scope: !10)
!29 = !DISubprogram(name: "cq_measure_si32", scope: !30, file: !30, line: 83, type: !31, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!30 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_E2", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!31 = !DISubroutineType(types: !32)
!32 = !{!13, !13}
!33 = !DISubprogram(name: "cq_theta_si32", scope: !30, file: !30, line: 38, type: !34, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!34 = !DISubroutineType(types: !35)
!35 = !{!13, !13, !36}
!36 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
