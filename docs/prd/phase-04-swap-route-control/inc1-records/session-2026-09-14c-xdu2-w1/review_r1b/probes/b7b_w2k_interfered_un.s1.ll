; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b7b_w2k_interfered_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b7b_w2k_interfered_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !21
    #dbg_value(i32 %1, !15, !DIExpression(), !22)
    #dbg_value(i32 0, !16, !DIExpression(), !22)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !23
    #dbg_value(i32 %2, !17, !DIExpression(), !24)
  %3 = lshr i32 %2, 1, !dbg !25
  %4 = and i32 %3, 1, !dbg !25
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2, !dbg !25
  %6 = and i32 %1, 1, !dbg !26
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !26
    #dbg_value(i32 poison, !16, !DIExpression(), !22)
  %8 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2, !dbg !27
    #dbg_value(i32 %8, !17, !DIExpression(), !24)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !28
    #dbg_value(i32 poison, !16, !DIExpression(), !22)
  %10 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !29
    #dbg_value(i32 %10, !19, !DIExpression(), !30)
  %11 = lshr i32 %10, 1, !dbg !31
  %12 = and i32 %11, 1, !dbg !31
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !31
  %14 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !32
    #dbg_value(i32 %21, !16, !DIExpression(), !22)
  %15 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 9.000000e-01) #2, !dbg !33
    #dbg_value(i32 %15, !19, !DIExpression(), !30)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !34
    #dbg_value(i32 %22, !16, !DIExpression(), !22)
  %17 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !35
  %18 = add i32 %7, %5, !dbg !36
  %19 = add i32 %18, %9, !dbg !37
  %20 = add i32 %19, %13, !dbg !38
  %21 = add i32 %20, %14, !dbg !39
  %22 = add nsw i32 %21, %16, !dbg !40
  %23 = add nsw i32 %22, %17, !dbg !41
  ret i32 %23, !dbg !42
}

declare !dbg !43 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !48 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !51 {
  %1 = tail call i32 @slice(), !dbg !52
  ret i32 %1, !dbg !53
}

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b7b_w2k_interfered_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "192f9c5ec7da858464f031df6b27aa2a")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocalVariable(name: "u", scope: !18, file: !8, line: 6, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 5)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 10, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 5)
!21 = !DILocation(line: 4, column: 13, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 6, column: 17, scope: !18)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 7, column: 14, scope: !18)
!26 = !DILocation(line: 7, column: 41, scope: !18)
!27 = !DILocation(line: 8, column: 13, scope: !18)
!28 = !DILocation(line: 9, column: 14, scope: !18)
!29 = !DILocation(line: 10, column: 17, scope: !20)
!30 = !DILocation(line: 0, scope: !20)
!31 = !DILocation(line: 11, column: 14, scope: !20)
!32 = !DILocation(line: 11, column: 41, scope: !20)
!33 = !DILocation(line: 12, column: 13, scope: !20)
!34 = !DILocation(line: 13, column: 14, scope: !20)
!35 = !DILocation(line: 14, column: 16, scope: !10)
!36 = !DILocation(line: 11, column: 39, scope: !20)
!37 = !DILocation(line: 7, column: 39, scope: !18)
!38 = !DILocation(line: 9, column: 11, scope: !18)
!39 = !DILocation(line: 11, column: 11, scope: !20)
!40 = !DILocation(line: 13, column: 11, scope: !20)
!41 = !DILocation(line: 14, column: 14, scope: !10)
!42 = !DILocation(line: 14, column: 5, scope: !10)
!43 = !DISubprogram(name: "cq_theta_si32", scope: !44, file: !44, line: 38, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!45 = !DISubroutineType(types: !46)
!46 = !{!13, !13, !47}
!47 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!48 = !DISubprogram(name: "cq_measure_si32", scope: !44, file: !44, line: 83, type: !49, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!49 = !DISubroutineType(types: !50)
!50 = !{!13, !13}
!51 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 16, type: !11, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!52 = !DILocation(line: 16, column: 25, scope: !51)
!53 = !DILocation(line: 16, column: 18, scope: !51)
