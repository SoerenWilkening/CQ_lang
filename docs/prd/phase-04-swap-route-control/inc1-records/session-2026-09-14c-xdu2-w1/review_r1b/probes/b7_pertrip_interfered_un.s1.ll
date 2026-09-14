; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b7_pertrip_interfered_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b7_pertrip_interfered_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 0, !15, !DIExpression(), !20)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !21
    #dbg_value(i32 %1, !16, !DIExpression(), !22)
  %2 = lshr i32 %1, 1, !dbg !23
  %3 = and i32 %2, 1, !dbg !23
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !23
    #dbg_value(i32 %4, !15, !DIExpression(), !20)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !24
    #dbg_value(i32 %5, !16, !DIExpression(), !22)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !25
  %7 = add nsw i32 %6, %4, !dbg !26
    #dbg_value(i32 %7, !15, !DIExpression(), !20)
  %8 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !27
    #dbg_value(i32 %8, !18, !DIExpression(), !28)
  %9 = lshr i32 %8, 1, !dbg !29
  %10 = and i32 %9, 1, !dbg !29
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !29
  %12 = add nsw i32 %7, %11, !dbg !30
    #dbg_value(i32 %12, !15, !DIExpression(), !20)
  %13 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 9.000000e-01) #2, !dbg !31
    #dbg_value(i32 %13, !18, !DIExpression(), !28)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !32
  %15 = add nsw i32 %12, %14, !dbg !33
    #dbg_value(i32 %15, !15, !DIExpression(), !20)
  ret i32 %15, !dbg !34
}

declare !dbg !35 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !40 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !43 {
    #dbg_value(i32 0, !15, !DIExpression(), !44)
  %1 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !46
    #dbg_value(i32 %1, !16, !DIExpression(), !47)
  %2 = lshr i32 %1, 1, !dbg !48
  %3 = and i32 %2, 1, !dbg !48
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !48
    #dbg_value(i32 %4, !15, !DIExpression(), !44)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !49
    #dbg_value(i32 %5, !16, !DIExpression(), !47)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !50
  %7 = add nsw i32 %6, %4, !dbg !51
    #dbg_value(i32 %7, !15, !DIExpression(), !44)
  %8 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !52
    #dbg_value(i32 %8, !18, !DIExpression(), !53)
  %9 = lshr i32 %8, 1, !dbg !54
  %10 = and i32 %9, 1, !dbg !54
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !54
  %12 = add nsw i32 %7, %11, !dbg !55
    #dbg_value(i32 %12, !15, !DIExpression(), !44)
  %13 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 9.000000e-01) #2, !dbg !56
    #dbg_value(i32 %13, !18, !DIExpression(), !53)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !57
  %15 = add nsw i32 %12, %14, !dbg !58
    #dbg_value(i32 %15, !15, !DIExpression(), !44)
  ret i32 %15, !dbg !59
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b7_pertrip_interfered_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "c3ad33cf885cc4ddc013f66762e48f55")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18}
!15 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "u", scope: !17, file: !8, line: 5, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 5)
!18 = !DILocalVariable(name: "u", scope: !19, file: !8, line: 9, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 5, column: 17, scope: !17)
!22 = !DILocation(line: 0, scope: !17)
!23 = !DILocation(line: 6, column: 14, scope: !17)
!24 = !DILocation(line: 7, column: 13, scope: !17)
!25 = !DILocation(line: 8, column: 14, scope: !17)
!26 = !DILocation(line: 8, column: 11, scope: !17)
!27 = !DILocation(line: 9, column: 17, scope: !19)
!28 = !DILocation(line: 0, scope: !19)
!29 = !DILocation(line: 10, column: 14, scope: !19)
!30 = !DILocation(line: 10, column: 11, scope: !19)
!31 = !DILocation(line: 11, column: 13, scope: !19)
!32 = !DILocation(line: 12, column: 14, scope: !19)
!33 = !DILocation(line: 12, column: 11, scope: !19)
!34 = !DILocation(line: 13, column: 5, scope: !10)
!35 = !DISubprogram(name: "cq_theta_si32", scope: !36, file: !36, line: 38, type: !37, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!36 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!37 = !DISubroutineType(types: !38)
!38 = !{!13, !13, !39}
!39 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!40 = !DISubprogram(name: "cq_measure_si32", scope: !36, file: !36, line: 83, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DISubroutineType(types: !42)
!42 = !{!13, !13}
!43 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!44 = !DILocation(line: 0, scope: !10, inlinedAt: !45)
!45 = distinct !DILocation(line: 15, column: 25, scope: !43)
!46 = !DILocation(line: 5, column: 17, scope: !17, inlinedAt: !45)
!47 = !DILocation(line: 0, scope: !17, inlinedAt: !45)
!48 = !DILocation(line: 6, column: 14, scope: !17, inlinedAt: !45)
!49 = !DILocation(line: 7, column: 13, scope: !17, inlinedAt: !45)
!50 = !DILocation(line: 8, column: 14, scope: !17, inlinedAt: !45)
!51 = !DILocation(line: 8, column: 11, scope: !17, inlinedAt: !45)
!52 = !DILocation(line: 9, column: 17, scope: !19, inlinedAt: !45)
!53 = !DILocation(line: 0, scope: !19, inlinedAt: !45)
!54 = !DILocation(line: 10, column: 14, scope: !19, inlinedAt: !45)
!55 = !DILocation(line: 10, column: 11, scope: !19, inlinedAt: !45)
!56 = !DILocation(line: 11, column: 13, scope: !19, inlinedAt: !45)
!57 = !DILocation(line: 12, column: 14, scope: !19, inlinedAt: !45)
!58 = !DILocation(line: 12, column: 11, scope: !19, inlinedAt: !45)
!59 = !DILocation(line: 15, column: 18, scope: !43)
