; ModuleID = 's3_live_rootmint_region_un.c'
source_filename = "s3_live_rootmint_region_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !16
    #dbg_value(i32 %1, !15, !DIExpression(), !17)
  %2 = and i32 %1, 2, !dbg !18
  %3 = icmp eq i32 %2, 0, !dbg !18
  br i1 %3, label %5, label %4, !dbg !20

4:                                                ; preds = %0
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !21
  br label %5, !dbg !21

5:                                                ; preds = %4, %0
  %6 = and i32 %1, 4, !dbg !22
  %7 = icmp eq i32 %6, 0, !dbg !22
  br i1 %7, label %9, label %8, !dbg !24

8:                                                ; preds = %5
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !25
  br label %9, !dbg !25

9:                                                ; preds = %8, %5
  %10 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !26
    #dbg_value(i32 %10, !15, !DIExpression(), !17)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !27
  ret i32 %11, !dbg !28
}

declare !dbg !29 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !34 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !37 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !40 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !41
    #dbg_value(i32 %1, !15, !DIExpression(), !43)
  %2 = and i32 %1, 2, !dbg !44
  %3 = icmp eq i32 %2, 0, !dbg !44
  br i1 %3, label %5, label %4, !dbg !45

4:                                                ; preds = %0
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !46
  br label %5, !dbg !46

5:                                                ; preds = %4, %0
  %6 = and i32 %1, 4, !dbg !47
  %7 = icmp eq i32 %6, 0, !dbg !47
  br i1 %7, label %9, label %8, !dbg !48

8:                                                ; preds = %5
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !49
  br label %9, !dbg !49

9:                                                ; preds = %5, %8
  %10 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !50
    #dbg_value(i32 %10, !15, !DIExpression(), !43)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !51
  ret i32 %11, !dbg !52
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
!8 = !DIFile(filename: "s3_live_rootmint_region_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "bcc13d2f056eb5ead7585c5f4f69b249")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocation(line: 4, column: 13, scope: !10)
!17 = !DILocation(line: 0, scope: !10)
!18 = !DILocation(line: 5, column: 18, scope: !19)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 9)
!20 = !DILocation(line: 5, column: 9, scope: !10)
!21 = !DILocation(line: 5, column: 23, scope: !19)
!22 = !DILocation(line: 6, column: 18, scope: !23)
!23 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 9)
!24 = !DILocation(line: 6, column: 9, scope: !10)
!25 = !DILocation(line: 6, column: 23, scope: !23)
!26 = !DILocation(line: 7, column: 9, scope: !10)
!27 = !DILocation(line: 8, column: 12, scope: !10)
!28 = !DILocation(line: 8, column: 5, scope: !10)
!29 = !DISubprogram(name: "cq_theta_si32", scope: !30, file: !30, line: 38, type: !31, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!30 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_S", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!31 = !DISubroutineType(types: !32)
!32 = !{!13, !13, !33}
!33 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!34 = !DISubprogram(name: "cq_phi", scope: !30, file: !30, line: 73, type: !35, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!35 = !DISubroutineType(types: !36)
!36 = !{null, !33}
!37 = !DISubprogram(name: "cq_measure_si32", scope: !30, file: !30, line: 83, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = !DISubroutineType(types: !39)
!39 = !{!13, !13}
!40 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!41 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !42)
!42 = distinct !DILocation(line: 10, column: 25, scope: !40)
!43 = !DILocation(line: 0, scope: !10, inlinedAt: !42)
!44 = !DILocation(line: 5, column: 18, scope: !19, inlinedAt: !42)
!45 = !DILocation(line: 5, column: 9, scope: !10, inlinedAt: !42)
!46 = !DILocation(line: 5, column: 23, scope: !19, inlinedAt: !42)
!47 = !DILocation(line: 6, column: 18, scope: !23, inlinedAt: !42)
!48 = !DILocation(line: 6, column: 9, scope: !10, inlinedAt: !42)
!49 = !DILocation(line: 6, column: 23, scope: !23, inlinedAt: !42)
!50 = !DILocation(line: 7, column: 9, scope: !10, inlinedAt: !42)
!51 = !DILocation(line: 8, column: 12, scope: !10, inlinedAt: !42)
!52 = !DILocation(line: 10, column: 18, scope: !40)
