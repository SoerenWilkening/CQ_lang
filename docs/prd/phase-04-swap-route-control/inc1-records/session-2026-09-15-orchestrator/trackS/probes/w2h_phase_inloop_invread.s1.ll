; ModuleID = 'w2h_phase_inloop_invread.c'
source_filename = "w2h_phase_inloop_invread.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i32 %1, !15, !DIExpression(), !23)
    #dbg_value(i32 0, !16, !DIExpression(), !23)
    #dbg_value(i32 0, !17, !DIExpression(), !24)
  %2 = and i32 %1, 1
  br label %6, !dbg !25

3:                                                ; preds = %13
  %4 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !26
  %5 = add nsw i32 %4, %19, !dbg !27
  ret i32 %5, !dbg !28

6:                                                ; preds = %0, %13
  %7 = phi i32 [ 0, %0 ], [ %19, %13 ]
  %8 = phi i32 [ 0, %0 ], [ %20, %13 ]
    #dbg_value(i32 %7, !16, !DIExpression(), !23)
    #dbg_value(i32 %8, !17, !DIExpression(), !24)
  %9 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !29
    #dbg_value(i32 %9, !19, !DIExpression(), !30)
  %10 = and i32 %9, 2, !dbg !31
  %11 = icmp eq i32 %10, 0, !dbg !31
  br i1 %11, label %13, label %12, !dbg !33

12:                                               ; preds = %6
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !34
  br label %13, !dbg !34

13:                                               ; preds = %12, %6
  %14 = lshr i32 %9, 2, !dbg !35
  %15 = and i32 %14, 1, !dbg !35
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !35
  %17 = tail call i32 @cq_measure_si32(i32 noundef %2) #2, !dbg !36
  %18 = add i32 %16, %7, !dbg !37
  %19 = add i32 %18, %17, !dbg !38
    #dbg_value(i32 %19, !16, !DIExpression(), !23)
  %20 = add nuw nsw i32 %8, 1, !dbg !39
    #dbg_value(i32 %20, !17, !DIExpression(), !24)
  %21 = icmp eq i32 %8, 0, !dbg !40
  br i1 %21, label %6, label %3, !dbg !25, !llvm.loop !41
}

declare !dbg !45 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !50 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !53 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !56 {
  %1 = tail call i32 @slice(), !dbg !57
  ret i32 %1, !dbg !58
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
!8 = !DIFile(filename: "w2h_phase_inloop_invread.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "57cc393e6aba321b771ada96a985d52f")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 5, type: !11, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 8, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 9, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 8, column: 33)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 8, column: 5)
!22 = !DILocation(line: 6, column: 14, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 8, column: 5, scope: !18)
!26 = !DILocation(line: 13, column: 16, scope: !10)
!27 = !DILocation(line: 13, column: 14, scope: !10)
!28 = !DILocation(line: 13, column: 5, scope: !10)
!29 = !DILocation(line: 9, column: 17, scope: !20)
!30 = !DILocation(line: 0, scope: !20)
!31 = !DILocation(line: 10, column: 22, scope: !32)
!32 = distinct !DILexicalBlock(scope: !20, file: !8, line: 10, column: 13)
!33 = !DILocation(line: 10, column: 13, scope: !20)
!34 = !DILocation(line: 10, column: 27, scope: !32)
!35 = !DILocation(line: 11, column: 14, scope: !20)
!36 = !DILocation(line: 11, column: 41, scope: !20)
!37 = !DILocation(line: 11, column: 39, scope: !20)
!38 = !DILocation(line: 11, column: 11, scope: !20)
!39 = !DILocation(line: 8, column: 28, scope: !21)
!40 = !DILocation(line: 8, column: 23, scope: !21)
!41 = distinct !{!41, !25, !42, !43, !44}
!42 = !DILocation(line: 12, column: 5, scope: !18)
!43 = !{!"llvm.loop.mustprogress"}
!44 = !{!"llvm.loop.unroll.disable"}
!45 = !DISubprogram(name: "cq_theta_si32", scope: !46, file: !46, line: 38, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_S", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!47 = !DISubroutineType(types: !48)
!48 = !{!13, !13, !49}
!49 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!50 = !DISubprogram(name: "cq_phi", scope: !46, file: !46, line: 73, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DISubroutineType(types: !52)
!52 = !{null, !49}
!53 = !DISubprogram(name: "cq_measure_si32", scope: !46, file: !46, line: 83, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!54 = !DISubroutineType(types: !55)
!55 = !{!13, !13}
!56 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !11, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!57 = !DILocation(line: 15, column: 25, scope: !56)
!58 = !DILocation(line: 15, column: 18, scope: !56)
