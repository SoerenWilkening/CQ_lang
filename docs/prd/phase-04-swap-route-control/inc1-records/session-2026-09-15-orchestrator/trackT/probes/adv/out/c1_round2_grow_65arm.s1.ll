; ModuleID = 'c1_round2_grow_65arm.c'
source_filename = "c1_round2_grow_65arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #3, !dbg !21
    #dbg_value(i32 %1, !15, !DIExpression(), !22)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 3.000000e-01) #3, !dbg !23
    #dbg_value(i32 %2, !16, !DIExpression(), !22)
    #dbg_value(i32 3, !17, !DIExpression(), !22)
  %3 = and i32 %1, 1, !dbg !24
  %4 = icmp eq i32 %3, 0, !dbg !24
  br i1 %4, label %7, label %5, !dbg !26

5:                                                ; preds = %0
  %6 = tail call i32 @helper(i32 noundef 4) #4, !dbg !27
    #dbg_value(i32 %6, !17, !DIExpression(), !22)
  br label %7, !dbg !28

7:                                                ; preds = %5, %0
  %8 = phi i32 [ %6, %5 ], [ 3, %0 ], !dbg !22
    #dbg_value(i32 %8, !17, !DIExpression(), !22)
    #dbg_value(i32 0, !18, !DIExpression(), !22)
    #dbg_value(i32 1, !19, !DIExpression(), !29)
  br label %15, !dbg !30

9:                                                ; preds = %15
  %10 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #3, !dbg !31
    #dbg_value(i32 %10, !16, !DIExpression(), !22)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3, !dbg !32
  %12 = add nsw i32 %11, %21, !dbg !33
  %13 = tail call i32 @cq_measure_si32(i32 noundef %1) #3, !dbg !34
  %14 = add nsw i32 %12, %13, !dbg !35
  ret i32 %14, !dbg !36

15:                                               ; preds = %7, %15
  %16 = phi i32 [ 1, %7 ], [ %22, %15 ]
  %17 = phi i32 [ 0, %7 ], [ %21, %15 ]
    #dbg_value(i32 %16, !19, !DIExpression(), !29)
    #dbg_value(i32 %17, !18, !DIExpression(), !22)
  %18 = ashr i32 %2, %16, !dbg !37
  %19 = and i32 %18, %8, !dbg !37
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #3, !dbg !37
  %21 = add nsw i32 %20, %17, !dbg !39
    #dbg_value(i32 %21, !18, !DIExpression(), !22)
  %22 = add nuw nsw i32 %16, 1, !dbg !40
    #dbg_value(i32 %22, !19, !DIExpression(), !29)
  %23 = icmp eq i32 %22, 3, !dbg !41
  br i1 %23, label %9, label %15, !dbg !30, !llvm.loop !42
}

declare !dbg !46 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare !dbg !51 i32 @helper(i32 noundef) local_unnamed_addr #2

declare !dbg !54 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !55 {
  %1 = tail call i32 @slice(), !dbg !56
  ret i32 %1, !dbg !57
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nounwind willreturn memory(none) }

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
!8 = !DIFile(filename: "c1_round2_grow_65arm.c", directory: "/Users/sorenwilkening/Desktop/CQ_T/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv", checksumkind: CSK_MD5, checksum: "f809daf8ca50638e732f5a6a3a324b83")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 11, type: !11, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !19}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 12, type: !13)
!16 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 13, type: !13)
!17 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 14, type: !13)
!18 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 16, type: !13)
!19 = !DILocalVariable(name: "k", scope: !20, file: !8, line: 17, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 17, column: 5)
!21 = !DILocation(line: 12, column: 13, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 13, column: 13, scope: !10)
!24 = !DILocation(line: 15, column: 11, scope: !25)
!25 = distinct !DILexicalBlock(scope: !10, file: !8, line: 15, column: 9)
!26 = !DILocation(line: 15, column: 9, scope: !10)
!27 = !DILocation(line: 15, column: 20, scope: !25)
!28 = !DILocation(line: 15, column: 16, scope: !25)
!29 = !DILocation(line: 0, scope: !20)
!30 = !DILocation(line: 17, column: 5, scope: !20)
!31 = !DILocation(line: 19, column: 9, scope: !10)
!32 = !DILocation(line: 20, column: 16, scope: !10)
!33 = !DILocation(line: 20, column: 14, scope: !10)
!34 = !DILocation(line: 20, column: 32, scope: !10)
!35 = !DILocation(line: 20, column: 30, scope: !10)
!36 = !DILocation(line: 20, column: 5, scope: !10)
!37 = !DILocation(line: 18, column: 14, scope: !38)
!38 = distinct !DILexicalBlock(scope: !20, file: !8, line: 17, column: 5)
!39 = !DILocation(line: 18, column: 11, scope: !38)
!40 = !DILocation(line: 17, column: 29, scope: !38)
!41 = !DILocation(line: 17, column: 23, scope: !38)
!42 = distinct !{!42, !30, !43, !44, !45}
!43 = !DILocation(line: 18, column: 14, scope: !20)
!44 = !{!"llvm.loop.mustprogress"}
!45 = !{!"llvm.loop.unroll.disable"}
!46 = !DISubprogram(name: "cq_theta_si32", scope: !47, file: !47, line: 38, type: !48, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!48 = !DISubroutineType(types: !49)
!49 = !{!13, !13, !50}
!50 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!51 = !DISubprogram(name: "helper", scope: !8, file: !8, line: 10, type: !52, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!52 = !DISubroutineType(types: !53)
!53 = !{!13, !13}
!54 = !DISubprogram(name: "cq_measure_si32", scope: !47, file: !47, line: 83, type: !52, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 22, type: !11, scopeLine: 22, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!56 = !DILocation(line: 22, column: 25, scope: !55)
!57 = !DILocation(line: 22, column: 18, scope: !55)
