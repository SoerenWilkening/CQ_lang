; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b2_carried_inloop_rot_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b2_carried_inloop_rot_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !17
    #dbg_value(i32 %1, !15, !DIExpression(), !18)
    #dbg_value(i32 0, !16, !DIExpression(), !18)
  %2 = lshr i32 %1, 1, !dbg !19
  %3 = and i32 %2, 1, !dbg !19
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !19
    #dbg_value(i32 %4, !16, !DIExpression(), !18)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e-01) #2, !dbg !20
    #dbg_value(i32 %5, !15, !DIExpression(), !18)
  %6 = lshr i32 %5, 2, !dbg !21
  %7 = and i32 %6, 1, !dbg !21
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !21
  %9 = add nsw i32 %8, %4, !dbg !22
    #dbg_value(i32 %9, !16, !DIExpression(), !18)
  %10 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 1.000000e-01) #2, !dbg !23
    #dbg_value(i32 %10, !15, !DIExpression(), !18)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !24
  %12 = add nsw i32 %9, %11, !dbg !25
  ret i32 %12, !dbg !26
}

declare !dbg !27 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !32 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !35 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !36
    #dbg_value(i32 %1, !15, !DIExpression(), !38)
    #dbg_value(i32 0, !16, !DIExpression(), !38)
  %2 = lshr i32 %1, 1, !dbg !39
  %3 = and i32 %2, 1, !dbg !39
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !39
    #dbg_value(i32 %4, !16, !DIExpression(), !38)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e-01) #2, !dbg !40
    #dbg_value(i32 %5, !15, !DIExpression(), !38)
  %6 = lshr i32 %5, 2, !dbg !41
  %7 = and i32 %6, 1, !dbg !41
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !41
  %9 = add nsw i32 %8, %4, !dbg !42
    #dbg_value(i32 %9, !16, !DIExpression(), !38)
  %10 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 1.000000e-01) #2, !dbg !43
    #dbg_value(i32 %10, !15, !DIExpression(), !38)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !44
  %12 = add nsw i32 %9, %11, !dbg !45
  ret i32 %12, !dbg !46
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b2_carried_inloop_rot_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "50eee5c94bbb28f76df26c8039874d6f")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocation(line: 3, column: 13, scope: !10)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 5, column: 10, scope: !10)
!20 = !DILocation(line: 5, column: 40, scope: !10)
!21 = !DILocation(line: 6, column: 10, scope: !10)
!22 = !DILocation(line: 6, column: 7, scope: !10)
!23 = !DILocation(line: 6, column: 40, scope: !10)
!24 = !DILocation(line: 7, column: 16, scope: !10)
!25 = !DILocation(line: 7, column: 14, scope: !10)
!26 = !DILocation(line: 7, column: 5, scope: !10)
!27 = !DISubprogram(name: "cq_theta_si32", scope: !28, file: !28, line: 38, type: !29, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!28 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!29 = !DISubroutineType(types: !30)
!30 = !{!13, !13, !31}
!31 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!32 = !DISubprogram(name: "cq_measure_si32", scope: !28, file: !28, line: 83, type: !33, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!33 = !DISubroutineType(types: !34)
!34 = !{!13, !13}
!35 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 9, type: !11, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!36 = !DILocation(line: 3, column: 13, scope: !10, inlinedAt: !37)
!37 = distinct !DILocation(line: 9, column: 25, scope: !35)
!38 = !DILocation(line: 0, scope: !10, inlinedAt: !37)
!39 = !DILocation(line: 5, column: 10, scope: !10, inlinedAt: !37)
!40 = !DILocation(line: 5, column: 40, scope: !10, inlinedAt: !37)
!41 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !37)
!42 = !DILocation(line: 6, column: 7, scope: !10, inlinedAt: !37)
!43 = !DILocation(line: 6, column: 40, scope: !10, inlinedAt: !37)
!44 = !DILocation(line: 7, column: 16, scope: !10, inlinedAt: !37)
!45 = !DILocation(line: 7, column: 14, scope: !10, inlinedAt: !37)
!46 = !DILocation(line: 9, column: 18, scope: !35)
