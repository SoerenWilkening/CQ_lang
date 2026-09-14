; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a7_two_registers_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a7_two_registers_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !18
    #dbg_value(i32 %1, !15, !DIExpression(), !19)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !20
    #dbg_value(i32 %2, !16, !DIExpression(), !19)
    #dbg_value(i32 0, !17, !DIExpression(), !19)
  %3 = lshr i32 %1, 1, !dbg !21
  %4 = and i32 %3, 1, !dbg !21
  %5 = lshr i32 %2, 1, !dbg !21
  %6 = and i32 %5, 1, !dbg !21
  %7 = add nuw nsw i32 %6, %4, !dbg !21
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !21
    #dbg_value(i32 %8, !17, !DIExpression(), !19)
  %9 = lshr i32 %1, 2, !dbg !22
  %10 = and i32 %9, 1, !dbg !22
  %11 = lshr i32 %2, 2, !dbg !22
  %12 = and i32 %11, 1, !dbg !22
  %13 = add nuw nsw i32 %12, %10, !dbg !22
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !22
  %15 = add nsw i32 %14, %8, !dbg !23
    #dbg_value(i32 %15, !17, !DIExpression(), !19)
  %16 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !24
    #dbg_value(i32 %16, !15, !DIExpression(), !19)
  %17 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 0x3FE6666666666666) #2, !dbg !25
    #dbg_value(i32 %17, !16, !DIExpression(), !19)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %16) #2, !dbg !26
  %19 = add nsw i32 %15, %18, !dbg !27
  %20 = tail call i32 @cq_measure_si32(i32 noundef %17) #2, !dbg !28
  %21 = add nsw i32 %19, %20, !dbg !29
  ret i32 %21, !dbg !30
}

declare !dbg !31 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !36 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !39 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !40
    #dbg_value(i32 %1, !15, !DIExpression(), !42)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !43
    #dbg_value(i32 %2, !16, !DIExpression(), !42)
    #dbg_value(i32 0, !17, !DIExpression(), !42)
  %3 = lshr i32 %1, 1, !dbg !44
  %4 = and i32 %3, 1, !dbg !44
  %5 = lshr i32 %2, 1, !dbg !44
  %6 = and i32 %5, 1, !dbg !44
  %7 = add nuw nsw i32 %6, %4, !dbg !44
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !44
    #dbg_value(i32 %8, !17, !DIExpression(), !42)
  %9 = lshr i32 %1, 2, !dbg !45
  %10 = and i32 %9, 1, !dbg !45
  %11 = lshr i32 %2, 2, !dbg !45
  %12 = and i32 %11, 1, !dbg !45
  %13 = add nuw nsw i32 %12, %10, !dbg !45
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !45
  %15 = add nsw i32 %14, %8, !dbg !46
    #dbg_value(i32 %15, !17, !DIExpression(), !42)
  %16 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !47
    #dbg_value(i32 %16, !15, !DIExpression(), !42)
  %17 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 0x3FE6666666666666) #2, !dbg !48
    #dbg_value(i32 %17, !16, !DIExpression(), !42)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %16) #2, !dbg !49
  %19 = add nsw i32 %15, %18, !dbg !50
  %20 = tail call i32 @cq_measure_si32(i32 noundef %17) #2, !dbg !51
  %21 = add nsw i32 %19, %20, !dbg !52
  ret i32 %21, !dbg !53
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/a7_two_registers_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "32ef49e1f53bb56d73d5e43f41485cd6")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "z", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!18 = !DILocation(line: 3, column: 13, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 4, column: 13, scope: !10)
!21 = !DILocation(line: 6, column: 10, scope: !10)
!22 = !DILocation(line: 7, column: 10, scope: !10)
!23 = !DILocation(line: 7, column: 7, scope: !10)
!24 = !DILocation(line: 8, column: 9, scope: !10)
!25 = !DILocation(line: 9, column: 9, scope: !10)
!26 = !DILocation(line: 10, column: 16, scope: !10)
!27 = !DILocation(line: 10, column: 14, scope: !10)
!28 = !DILocation(line: 10, column: 32, scope: !10)
!29 = !DILocation(line: 10, column: 30, scope: !10)
!30 = !DILocation(line: 10, column: 5, scope: !10)
!31 = !DISubprogram(name: "cq_theta_si32", scope: !32, file: !32, line: 38, type: !33, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!32 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!33 = !DISubroutineType(types: !34)
!34 = !{!13, !13, !35}
!35 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!36 = !DISubprogram(name: "cq_measure_si32", scope: !32, file: !32, line: 83, type: !37, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DISubroutineType(types: !38)
!38 = !{!13, !13}
!39 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 12, type: !11, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!40 = !DILocation(line: 3, column: 13, scope: !10, inlinedAt: !41)
!41 = distinct !DILocation(line: 12, column: 25, scope: !39)
!42 = !DILocation(line: 0, scope: !10, inlinedAt: !41)
!43 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !41)
!44 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !41)
!45 = !DILocation(line: 7, column: 10, scope: !10, inlinedAt: !41)
!46 = !DILocation(line: 7, column: 7, scope: !10, inlinedAt: !41)
!47 = !DILocation(line: 8, column: 9, scope: !10, inlinedAt: !41)
!48 = !DILocation(line: 9, column: 9, scope: !10, inlinedAt: !41)
!49 = !DILocation(line: 10, column: 16, scope: !10, inlinedAt: !41)
!50 = !DILocation(line: 10, column: 14, scope: !10, inlinedAt: !41)
!51 = !DILocation(line: 10, column: 32, scope: !10, inlinedAt: !41)
!52 = !DILocation(line: 10, column: 30, scope: !10, inlinedAt: !41)
!53 = !DILocation(line: 12, column: 18, scope: !39)
