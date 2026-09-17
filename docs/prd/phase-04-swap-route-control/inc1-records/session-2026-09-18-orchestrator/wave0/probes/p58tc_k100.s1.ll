; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_k100.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_k100.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
  br label %3, !dbg !25

2:                                                ; preds = %3
  ret i32 %12, !dbg !26

3:                                                ; preds = %1, %3
  %4 = phi i32 [ 0, %1 ], [ %12, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %13, %3 ]
    #dbg_value(i32 %4, !16, !DIExpression(), !23)
    #dbg_value(i32 %5, !17, !DIExpression(), !24)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2, !dbg !27
    #dbg_value(i32 %6, !19, !DIExpression(), !28)
  %7 = shl nsw i32 %6, 1, !dbg !29
    #dbg_value(i32 %7, !22, !DIExpression(), !28)
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 5.000000e-01) #2, !dbg !30
    #dbg_value(i32 %8, !22, !DIExpression(), !28)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !31
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !32
  %11 = add i32 %9, %4, !dbg !33
  %12 = add i32 %11, %10, !dbg !34
    #dbg_value(i32 %12, !16, !DIExpression(), !23)
  %13 = add nuw nsw i32 %5, 1, !dbg !35
    #dbg_value(i32 %13, !17, !DIExpression(), !24)
  %14 = icmp eq i32 %13, 100, !dbg !36
  br i1 %14, label %2, label %3, !dbg !25, !llvm.loop !37
}

declare !dbg !41 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !46 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !47 {
    #dbg_value(i32 1, !15, !DIExpression(), !50)
    #dbg_value(i32 0, !16, !DIExpression(), !50)
    #dbg_value(i32 0, !17, !DIExpression(), !52)
  br label %1, !dbg !53

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %10, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %11, %1 ]
    #dbg_value(i32 %2, !16, !DIExpression(), !50)
    #dbg_value(i32 %3, !17, !DIExpression(), !52)
  %4 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 2.500000e-01) #2, !dbg !54
    #dbg_value(i32 %4, !19, !DIExpression(), !55)
  %5 = shl nsw i32 %4, 1, !dbg !56
    #dbg_value(i32 %5, !22, !DIExpression(), !55)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #2, !dbg !57
    #dbg_value(i32 %6, !22, !DIExpression(), !55)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4) #2, !dbg !58
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !59
  %9 = add i32 %7, %2, !dbg !60
  %10 = add i32 %9, %8, !dbg !61
    #dbg_value(i32 %10, !16, !DIExpression(), !50)
  %11 = add nuw nsw i32 %3, 1, !dbg !62
    #dbg_value(i32 %11, !17, !DIExpression(), !52)
  %12 = icmp eq i32 %11, 100, !dbg !63
  br i1 %12, label %13, label %1, !dbg !53, !llvm.loop !64

13:                                               ; preds = %1
  ret i32 %10, !dbg !66
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/wave0/probes/p58tc_k100.c", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang", checksumkind: CSK_MD5, checksum: "9bddbcc9562e59cc97a31c69eff2027e")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 1, type: !11, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19, !22}
!15 = !DILocalVariable(name: "x", arg: 1, scope: !10, file: !8, line: 1, type: !13)
!16 = !DILocalVariable(name: "acc", scope: !10, file: !8, line: 2, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 3, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 3, column: 3)
!19 = !DILocalVariable(name: "q", scope: !20, file: !8, line: 4, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 3, column: 33)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 3, column: 3)
!22 = !DILocalVariable(name: "w", scope: !20, file: !8, line: 5, type: !13)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 3, column: 3, scope: !18)
!26 = !DILocation(line: 9, column: 3, scope: !10)
!27 = !DILocation(line: 4, column: 13, scope: !20)
!28 = !DILocation(line: 0, scope: !20)
!29 = !DILocation(line: 5, column: 15, scope: !20)
!30 = !DILocation(line: 6, column: 9, scope: !20)
!31 = !DILocation(line: 7, column: 12, scope: !20)
!32 = !DILocation(line: 7, column: 28, scope: !20)
!33 = !DILocation(line: 7, column: 26, scope: !20)
!34 = !DILocation(line: 7, column: 9, scope: !20)
!35 = !DILocation(line: 3, column: 28, scope: !21)
!36 = !DILocation(line: 3, column: 21, scope: !21)
!37 = distinct !{!37, !25, !38, !39, !40}
!38 = !DILocation(line: 8, column: 3, scope: !18)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !{!"llvm.loop.unroll.disable"}
!41 = !DISubprogram(name: "cq_theta_si32", scope: !42, file: !42, line: 38, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!43 = !DISubroutineType(types: !44)
!44 = !{!13, !13, !45}
!45 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!46 = !DISubprogram(name: "cq_measure_si32", scope: !42, file: !42, line: 83, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !48, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!48 = !DISubroutineType(types: !49)
!49 = !{!13}
!50 = !DILocation(line: 0, scope: !10, inlinedAt: !51)
!51 = distinct !DILocation(line: 11, column: 25, scope: !47)
!52 = !DILocation(line: 0, scope: !18, inlinedAt: !51)
!53 = !DILocation(line: 3, column: 3, scope: !18, inlinedAt: !51)
!54 = !DILocation(line: 4, column: 13, scope: !20, inlinedAt: !51)
!55 = !DILocation(line: 0, scope: !20, inlinedAt: !51)
!56 = !DILocation(line: 5, column: 15, scope: !20, inlinedAt: !51)
!57 = !DILocation(line: 6, column: 9, scope: !20, inlinedAt: !51)
!58 = !DILocation(line: 7, column: 12, scope: !20, inlinedAt: !51)
!59 = !DILocation(line: 7, column: 28, scope: !20, inlinedAt: !51)
!60 = !DILocation(line: 7, column: 26, scope: !20, inlinedAt: !51)
!61 = !DILocation(line: 7, column: 9, scope: !20, inlinedAt: !51)
!62 = !DILocation(line: 3, column: 28, scope: !21, inlinedAt: !51)
!63 = !DILocation(line: 3, column: 21, scope: !21, inlinedAt: !51)
!64 = distinct !{!64, !53, !65, !39, !40}
!65 = !DILocation(line: 8, column: 3, scope: !18, inlinedAt: !51)
!66 = !DILocation(line: 11, column: 18, scope: !47)
