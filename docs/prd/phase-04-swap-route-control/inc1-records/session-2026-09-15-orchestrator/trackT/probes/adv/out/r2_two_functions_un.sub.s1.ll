; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r2_two_functions_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r2_two_functions_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ka() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !17
    #dbg_value(i32 %1, !15, !DIExpression(), !18)
    #dbg_value(i32 0, !16, !DIExpression(), !18)
  %2 = lshr i32 %1, 1, !dbg !19
  %3 = and i32 %2, 1, !dbg !19
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !19
    #dbg_value(i32 %4, !16, !DIExpression(), !18)
  %5 = lshr i32 %1, 2, !dbg !20
  %6 = and i32 %5, 1, !dbg !20
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !20
  %8 = add nsw i32 %7, %4, !dbg !21
    #dbg_value(i32 %8, !16, !DIExpression(), !18)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !22
    #dbg_value(i32 %9, !15, !DIExpression(), !18)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !23
  %11 = add nsw i32 %8, %10, !dbg !24
  ret i32 %11, !dbg !25
}

declare !dbg !26 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !31 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @kb() local_unnamed_addr #0 !dbg !34 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !39
    #dbg_value(i32 %1, !36, !DIExpression(), !40)
  %2 = mul nsw i32 %1, 3, !dbg !41
    #dbg_value(i32 %2, !37, !DIExpression(), !40)
    #dbg_value(i32 0, !38, !DIExpression(), !40)
  %3 = lshr i32 %2, 1, !dbg !42
  %4 = and i32 %3, 1, !dbg !42
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #2, !dbg !42
    #dbg_value(i32 %5, !38, !DIExpression(), !40)
  %6 = lshr i32 %2, 2, !dbg !43
  %7 = and i32 %6, 1, !dbg !43
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !43
  %9 = add nsw i32 %8, %5, !dbg !44
    #dbg_value(i32 %9, !38, !DIExpression(), !40)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !45
  %11 = add nsw i32 %9, %10, !dbg !46
  ret i32 %11, !dbg !47
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !48 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !49
    #dbg_value(i32 %1, !15, !DIExpression(), !51)
    #dbg_value(i32 0, !16, !DIExpression(), !51)
  %2 = lshr i32 %1, 1, !dbg !52
  %3 = and i32 %2, 1, !dbg !52
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !52
    #dbg_value(i32 %4, !16, !DIExpression(), !51)
  %5 = lshr i32 %1, 2, !dbg !53
  %6 = and i32 %5, 1, !dbg !53
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !53
    #dbg_value(i32 poison, !16, !DIExpression(), !51)
  %8 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !54
    #dbg_value(i32 %8, !15, !DIExpression(), !51)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !55
  %10 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !56
    #dbg_value(i32 %10, !36, !DIExpression(), !58)
  %11 = mul nsw i32 %10, 3, !dbg !59
    #dbg_value(i32 %11, !37, !DIExpression(), !58)
    #dbg_value(i32 0, !38, !DIExpression(), !58)
  %12 = lshr i32 %11, 1, !dbg !60
  %13 = and i32 %12, 1, !dbg !60
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #2, !dbg !60
    #dbg_value(i32 %14, !38, !DIExpression(), !58)
  %15 = lshr i32 %11, 2, !dbg !61
  %16 = and i32 %15, 1, !dbg !61
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #2, !dbg !61
    #dbg_value(i32 poison, !38, !DIExpression(), !58)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !62
  %19 = add i32 %7, %4, !dbg !63
  %20 = add i32 %19, %9, !dbg !64
  %21 = add i32 %20, %14, !dbg !65
  %22 = add i32 %21, %17, !dbg !66
  %23 = add i32 %22, %18, !dbg !67
  ret i32 %23, !dbg !68
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r2_two_functions_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "d1c54e24225a17591605197027f8a4b0")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "ka", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocation(line: 3, column: 13, scope: !10)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 5, column: 10, scope: !10)
!20 = !DILocation(line: 6, column: 10, scope: !10)
!21 = !DILocation(line: 6, column: 7, scope: !10)
!22 = !DILocation(line: 7, column: 9, scope: !10)
!23 = !DILocation(line: 8, column: 16, scope: !10)
!24 = !DILocation(line: 8, column: 14, scope: !10)
!25 = !DILocation(line: 8, column: 5, scope: !10)
!26 = !DISubprogram(name: "cq_theta_si32", scope: !27, file: !27, line: 38, type: !28, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!27 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!28 = !DISubroutineType(types: !29)
!29 = !{!13, !13, !30}
!30 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!31 = !DISubprogram(name: "cq_measure_si32", scope: !27, file: !27, line: 83, type: !32, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!32 = !DISubroutineType(types: !33)
!33 = !{!13, !13}
!34 = distinct !DISubprogram(name: "kb", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !35)
!35 = !{!36, !37, !38}
!36 = !DILocalVariable(name: "y", scope: !34, file: !8, line: 11, type: !13)
!37 = !DILocalVariable(name: "p", scope: !34, file: !8, line: 12, type: !13)
!38 = !DILocalVariable(name: "s", scope: !34, file: !8, line: 13, type: !13)
!39 = !DILocation(line: 11, column: 13, scope: !34)
!40 = !DILocation(line: 0, scope: !34)
!41 = !DILocation(line: 12, column: 15, scope: !34)
!42 = !DILocation(line: 14, column: 10, scope: !34)
!43 = !DILocation(line: 15, column: 10, scope: !34)
!44 = !DILocation(line: 15, column: 7, scope: !34)
!45 = !DILocation(line: 16, column: 16, scope: !34)
!46 = !DILocation(line: 16, column: 14, scope: !34)
!47 = !DILocation(line: 16, column: 5, scope: !34)
!48 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 18, type: !11, scopeLine: 18, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!49 = !DILocation(line: 3, column: 13, scope: !10, inlinedAt: !50)
!50 = distinct !DILocation(line: 18, column: 25, scope: !48)
!51 = !DILocation(line: 0, scope: !10, inlinedAt: !50)
!52 = !DILocation(line: 5, column: 10, scope: !10, inlinedAt: !50)
!53 = !DILocation(line: 6, column: 10, scope: !10, inlinedAt: !50)
!54 = !DILocation(line: 7, column: 9, scope: !10, inlinedAt: !50)
!55 = !DILocation(line: 8, column: 16, scope: !10, inlinedAt: !50)
!56 = !DILocation(line: 11, column: 13, scope: !34, inlinedAt: !57)
!57 = distinct !DILocation(line: 18, column: 32, scope: !48)
!58 = !DILocation(line: 0, scope: !34, inlinedAt: !57)
!59 = !DILocation(line: 12, column: 15, scope: !34, inlinedAt: !57)
!60 = !DILocation(line: 14, column: 10, scope: !34, inlinedAt: !57)
!61 = !DILocation(line: 15, column: 10, scope: !34, inlinedAt: !57)
!62 = !DILocation(line: 16, column: 16, scope: !34, inlinedAt: !57)
!63 = !DILocation(line: 15, column: 7, scope: !34, inlinedAt: !57)
!64 = !DILocation(line: 16, column: 14, scope: !34, inlinedAt: !57)
!65 = !DILocation(line: 6, column: 7, scope: !10, inlinedAt: !50)
!66 = !DILocation(line: 8, column: 14, scope: !10, inlinedAt: !50)
!67 = !DILocation(line: 18, column: 30, scope: !48)
!68 = !DILocation(line: 18, column: 18, scope: !48)
