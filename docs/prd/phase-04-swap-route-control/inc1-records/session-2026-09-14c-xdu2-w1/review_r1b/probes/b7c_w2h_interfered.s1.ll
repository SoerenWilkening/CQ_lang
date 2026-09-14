; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b7c_w2h_interfered.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b7c_w2h_interfered.c"
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
  %5 = add nsw i32 %4, %22, !dbg !27
  ret i32 %5, !dbg !28

6:                                                ; preds = %0, %13
  %7 = phi i32 [ 0, %0 ], [ %23, %13 ]
  %8 = phi i32 [ 0, %0 ], [ %22, %13 ]
    #dbg_value(i32 %7, !17, !DIExpression(), !24)
    #dbg_value(i32 %8, !16, !DIExpression(), !23)
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
    #dbg_value(i32 %21, !16, !DIExpression(), !23)
  %18 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 9.000000e-01) #2, !dbg !37
    #dbg_value(i32 %18, !19, !DIExpression(), !30)
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #2, !dbg !38
  %20 = add i32 %16, %8, !dbg !39
  %21 = add i32 %20, %17, !dbg !40
  %22 = add nsw i32 %21, %19, !dbg !41
    #dbg_value(i32 %22, !16, !DIExpression(), !23)
  %23 = add nuw nsw i32 %7, 1, !dbg !42
    #dbg_value(i32 %23, !17, !DIExpression(), !24)
  %24 = icmp eq i32 %7, 0, !dbg !43
  br i1 %24, label %6, label %3, !dbg !25, !llvm.loop !44
}

declare !dbg !48 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !53 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !56 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !59 {
  %1 = tail call i32 @slice(), !dbg !60
  ret i32 %1, !dbg !61
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b7c_w2h_interfered.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "d60d9543509a665810945e5139aa88f7")
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
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 7, column: 33)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 7, column: 5)
!22 = !DILocation(line: 5, column: 14, scope: !10)
!23 = !DILocation(line: 0, scope: !10)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 7, column: 5, scope: !18)
!26 = !DILocation(line: 14, column: 16, scope: !10)
!27 = !DILocation(line: 14, column: 14, scope: !10)
!28 = !DILocation(line: 14, column: 5, scope: !10)
!29 = !DILocation(line: 8, column: 17, scope: !20)
!30 = !DILocation(line: 0, scope: !20)
!31 = !DILocation(line: 9, column: 22, scope: !32)
!32 = distinct !DILexicalBlock(scope: !20, file: !8, line: 9, column: 13)
!33 = !DILocation(line: 9, column: 13, scope: !20)
!34 = !DILocation(line: 9, column: 27, scope: !32)
!35 = !DILocation(line: 10, column: 14, scope: !20)
!36 = !DILocation(line: 10, column: 41, scope: !20)
!37 = !DILocation(line: 11, column: 13, scope: !20)
!38 = !DILocation(line: 12, column: 14, scope: !20)
!39 = !DILocation(line: 10, column: 39, scope: !20)
!40 = !DILocation(line: 10, column: 11, scope: !20)
!41 = !DILocation(line: 12, column: 11, scope: !20)
!42 = !DILocation(line: 7, column: 28, scope: !21)
!43 = !DILocation(line: 7, column: 23, scope: !21)
!44 = distinct !{!44, !25, !45, !46, !47}
!45 = !DILocation(line: 13, column: 5, scope: !18)
!46 = !{!"llvm.loop.mustprogress"}
!47 = !{!"llvm.loop.unroll.disable"}
!48 = !DISubprogram(name: "cq_theta_si32", scope: !49, file: !49, line: 38, type: !50, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!49 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!50 = !DISubroutineType(types: !51)
!51 = !{!13, !13, !52}
!52 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!53 = !DISubprogram(name: "cq_phi", scope: !49, file: !49, line: 73, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!54 = !DISubroutineType(types: !55)
!55 = !{null, !52}
!56 = !DISubprogram(name: "cq_measure_si32", scope: !49, file: !49, line: 83, type: !57, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!57 = !DISubroutineType(types: !58)
!58 = !{!13, !13}
!59 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 16, type: !11, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!60 = !DILocation(line: 16, column: 25, scope: !59)
!61 = !DILocation(line: 16, column: 18, scope: !59)
