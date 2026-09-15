; ModuleID = 's2_live_derived_region_un.c'
source_filename = "s2_live_derived_region_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !18
    #dbg_value(i32 %1, !15, !DIExpression(), !19)
  %2 = mul nsw i32 %1, 3, !dbg !20
    #dbg_value(i32 %2, !16, !DIExpression(), !19)
    #dbg_value(i32 0, !17, !DIExpression(), !19)
  %3 = and i32 %2, 2, !dbg !21
  %4 = icmp eq i32 %3, 0, !dbg !21
  br i1 %4, label %6, label %5, !dbg !23

5:                                                ; preds = %0
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !24
  br label %6, !dbg !24

6:                                                ; preds = %5, %0
  %7 = and i32 %2, 4, !dbg !25
  %8 = icmp eq i32 %7, 0, !dbg !25
  br i1 %8, label %10, label %9, !dbg !27

9:                                                ; preds = %6
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !28
  br label %10, !dbg !28

10:                                               ; preds = %9, %6
  %11 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !29
    #dbg_value(i32 %11, !15, !DIExpression(), !19)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !30
  ret i32 %12, !dbg !31
}

declare !dbg !32 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !37 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !40 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !43 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !44
    #dbg_value(i32 %1, !15, !DIExpression(), !46)
  %2 = mul nsw i32 %1, 3, !dbg !47
    #dbg_value(i32 %2, !16, !DIExpression(), !46)
    #dbg_value(i32 0, !17, !DIExpression(), !46)
  %3 = and i32 %2, 2, !dbg !48
  %4 = icmp eq i32 %3, 0, !dbg !48
  br i1 %4, label %6, label %5, !dbg !49

5:                                                ; preds = %0
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !50
  br label %6, !dbg !50

6:                                                ; preds = %5, %0
  %7 = and i32 %2, 4, !dbg !51
  %8 = icmp eq i32 %7, 0, !dbg !51
  br i1 %8, label %10, label %9, !dbg !52

9:                                                ; preds = %6
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !53
  br label %10, !dbg !53

10:                                               ; preds = %6, %9
  %11 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !54
    #dbg_value(i32 %11, !15, !DIExpression(), !46)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #2, !dbg !55
  ret i32 %12, !dbg !56
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
!8 = !DIFile(filename: "s2_live_derived_region_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "0fe4aac5f33fc8c44f6be61e27188839")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "p", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 6, type: !13)
!18 = !DILocation(line: 4, column: 13, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 5, column: 15, scope: !10)
!21 = !DILocation(line: 7, column: 18, scope: !22)
!22 = distinct !DILexicalBlock(scope: !10, file: !8, line: 7, column: 9)
!23 = !DILocation(line: 7, column: 9, scope: !10)
!24 = !DILocation(line: 7, column: 23, scope: !22)
!25 = !DILocation(line: 8, column: 18, scope: !26)
!26 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 9)
!27 = !DILocation(line: 8, column: 9, scope: !10)
!28 = !DILocation(line: 8, column: 23, scope: !26)
!29 = !DILocation(line: 9, column: 9, scope: !10)
!30 = !DILocation(line: 10, column: 16, scope: !10)
!31 = !DILocation(line: 10, column: 5, scope: !10)
!32 = !DISubprogram(name: "cq_theta_si32", scope: !33, file: !33, line: 38, type: !34, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!33 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_S", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!34 = !DISubroutineType(types: !35)
!35 = !{!13, !13, !36}
!36 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!37 = !DISubprogram(name: "cq_phi", scope: !33, file: !33, line: 73, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = !DISubroutineType(types: !39)
!39 = !{null, !36}
!40 = !DISubprogram(name: "cq_measure_si32", scope: !33, file: !33, line: 83, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DISubroutineType(types: !42)
!42 = !{!13, !13}
!43 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 12, type: !11, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!44 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !45)
!45 = distinct !DILocation(line: 12, column: 25, scope: !43)
!46 = !DILocation(line: 0, scope: !10, inlinedAt: !45)
!47 = !DILocation(line: 5, column: 15, scope: !10, inlinedAt: !45)
!48 = !DILocation(line: 7, column: 18, scope: !22, inlinedAt: !45)
!49 = !DILocation(line: 7, column: 9, scope: !10, inlinedAt: !45)
!50 = !DILocation(line: 7, column: 23, scope: !22, inlinedAt: !45)
!51 = !DILocation(line: 8, column: 18, scope: !26, inlinedAt: !45)
!52 = !DILocation(line: 8, column: 9, scope: !10, inlinedAt: !45)
!53 = !DILocation(line: 8, column: 23, scope: !26, inlinedAt: !45)
!54 = !DILocation(line: 9, column: 9, scope: !10, inlinedAt: !45)
!55 = !DILocation(line: 10, column: 16, scope: !10, inlinedAt: !45)
!56 = !DILocation(line: 12, column: 18, scope: !43)
