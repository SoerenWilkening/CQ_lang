; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r5_switch_in_body.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r5_switch_in_body.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i32 %1, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 1, !17, !DIExpression(), !24)
  br label %6, !dbg !25

2:                                                ; preds = %14
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !26
    #dbg_value(i32 %3, !15, !DIExpression(), !23)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !27
  %5 = add nsw i32 %4, %16, !dbg !28
  ret i32 %5, !dbg !29

6:                                                ; preds = %0, %14
  %7 = phi i32 [ 1, %0 ], [ %17, %14 ]
  %8 = phi i32 [ 0, %0 ], [ %16, %14 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !24)
    #dbg_value(i32 %8, !16, !DIExpression(), !23)
  %9 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !30
    #dbg_value(i32 %9, !19, !DIExpression(), !31)
  %10 = shl nuw nsw i32 1, %7, !dbg !32
  %11 = and i32 %10, %1, !dbg !32
  %12 = icmp eq i32 %11, 0, !dbg !32
  br i1 %12, label %14, label %13, !dbg !34

13:                                               ; preds = %6
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !35
  br label %14, !dbg !35

14:                                               ; preds = %13, %6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !36
  %16 = add nsw i32 %15, %8, !dbg !37
    #dbg_value(i32 %16, !16, !DIExpression(), !23)
  %17 = add nuw nsw i32 %7, 1, !dbg !38
    #dbg_value(i32 %17, !17, !DIExpression(), !24)
  %18 = icmp eq i32 %17, 3, !dbg !39
  br i1 %18, label %2, label %6, !dbg !25, !llvm.loop !40
}

declare !dbg !44 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !49 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !52 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !55 {
  %1 = tail call i32 @slice(), !dbg !56
  ret i32 %1, !dbg !57
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r5_switch_in_body.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "2415497289726a4f8f6aec63872a450b")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 4, type: !11, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 5, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 6, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 7, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 7, column: 5)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 8, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 7, column: 34)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 7, column: 5)
!22 = !DILocation(line: 5, column: 13, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 7, column: 5, scope: !18)
!26 = !DILocation(line: 12, column: 9, scope: !10)
!27 = !DILocation(line: 13, column: 16, scope: !10)
!28 = !DILocation(line: 13, column: 14, scope: !10)
!29 = !DILocation(line: 13, column: 5, scope: !10)
!30 = !DILocation(line: 8, column: 17, scope: !20)
!31 = !DILocation(line: 0, scope: !20)
!32 = !DILocation(line: 9, column: 22, scope: !33)
!33 = distinct !DILexicalBlock(scope: !20, file: !8, line: 9, column: 13)
!34 = !DILocation(line: 9, column: 13, scope: !20)
!35 = !DILocation(line: 9, column: 27, scope: !33)
!36 = !DILocation(line: 10, column: 14, scope: !20)
!37 = !DILocation(line: 10, column: 11, scope: !20)
!38 = !DILocation(line: 7, column: 29, scope: !21)
!39 = !DILocation(line: 7, column: 23, scope: !21)
!40 = distinct !{!40, !25, !41, !42, !43}
!41 = !DILocation(line: 11, column: 5, scope: !18)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = !DISubprogram(name: "cq_theta_si32", scope: !45, file: !45, line: 38, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!46 = !DISubroutineType(types: !47)
!47 = !{!13, !13, !48}
!48 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!49 = !DISubprogram(name: "cq_phi", scope: !45, file: !45, line: 73, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!50 = !DISubroutineType(types: !51)
!51 = !{null, !48}
!52 = !DISubprogram(name: "cq_measure_si32", scope: !45, file: !45, line: 83, type: !53, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!53 = !DISubroutineType(types: !54)
!54 = !{!13, !13}
!55 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!56 = !DILocation(line: 15, column: 25, scope: !55)
!57 = !DILocation(line: 15, column: 18, scope: !55)
