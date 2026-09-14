; ModuleID = 'src/r5e_nested_invariant.c'
source_filename = "src/r5e_nested_invariant.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !27
    #dbg_value(i32 %1, !15, !DIExpression(), !28)
    #dbg_value(i32 0, !16, !DIExpression(), !28)
    #dbg_value(i32 0, !17, !DIExpression(), !29)
  br label %2, !dbg !30

2:                                                ; preds = %0, %2
  %3 = phi i32 [ 0, %0 ], [ %7, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %8, %2 ]
    #dbg_value(i32 %3, !16, !DIExpression(), !28)
    #dbg_value(i32 %4, !17, !DIExpression(), !29)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e-01) #2, !dbg !31
    #dbg_value(i32 %5, !19, !DIExpression(), !32)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #2, !dbg !33
  %7 = add nsw i32 %6, %3, !dbg !34
    #dbg_value(i32 %7, !16, !DIExpression(), !28)
  %8 = add nuw nsw i32 %4, 1, !dbg !35
    #dbg_value(i32 %8, !17, !DIExpression(), !29)
  %9 = icmp eq i32 %4, 0, !dbg !36
  br i1 %9, label %2, label %11, !dbg !30, !llvm.loop !37

10:                                               ; preds = %11
  ret i32 %16, !dbg !41

11:                                               ; preds = %2, %11
  %12 = phi i32 [ %16, %11 ], [ %7, %2 ]
  %13 = phi i32 [ %17, %11 ], [ 0, %2 ]
    #dbg_value(i32 %12, !16, !DIExpression(), !28)
    #dbg_value(i32 %13, !22, !DIExpression(), !42)
  %14 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.000000e-01) #2, !dbg !43
    #dbg_value(i32 %14, !24, !DIExpression(), !44)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2, !dbg !45
  %16 = add nsw i32 %15, %12, !dbg !46
    #dbg_value(i32 %16, !16, !DIExpression(), !28)
  %17 = add nuw nsw i32 %13, 1, !dbg !47
    #dbg_value(i32 %17, !22, !DIExpression(), !42)
  %18 = icmp eq i32 %13, 0, !dbg !48
  br i1 %18, label %11, label %10, !dbg !49, !llvm.loop !50
}

declare !dbg !52 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !57 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/r5e_nested_invariant.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "157ecd5b582d58202207e87a8067d73c")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19, !22, !24}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 4, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!19 = !DILocalVariable(name: "b", scope: !20, file: !8, line: 4, type: !13)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 4, column: 23)
!21 = distinct !DILexicalBlock(scope: !18, file: !8, line: 4, column: 3)
!22 = !DILocalVariable(name: "j", scope: !23, file: !8, line: 5, type: !13)
!23 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 3)
!24 = !DILocalVariable(name: "c", scope: !25, file: !8, line: 5, type: !13)
!25 = distinct !DILexicalBlock(scope: !26, file: !8, line: 5, column: 23)
!26 = distinct !DILexicalBlock(scope: !23, file: !8, line: 5, column: 3)
!27 = !DILocation(line: 3, column: 23, scope: !10)
!28 = !DILocation(line: 0, scope: !10)
!29 = !DILocation(line: 0, scope: !18)
!30 = !DILocation(line: 4, column: 3, scope: !18)
!31 = !DILocation(line: 4, column: 31, scope: !20)
!32 = !DILocation(line: 0, scope: !20)
!33 = !DILocation(line: 4, column: 51, scope: !20)
!34 = !DILocation(line: 4, column: 49, scope: !20)
!35 = !DILocation(line: 4, column: 20, scope: !21)
!36 = !DILocation(line: 4, column: 16, scope: !21)
!37 = distinct !{!37, !30, !38, !39, !40}
!38 = !DILocation(line: 4, column: 66, scope: !18)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !{!"llvm.loop.unroll.disable"}
!41 = !DILocation(line: 5, column: 68, scope: !10)
!42 = !DILocation(line: 0, scope: !23)
!43 = !DILocation(line: 5, column: 31, scope: !25)
!44 = !DILocation(line: 0, scope: !25)
!45 = !DILocation(line: 5, column: 51, scope: !25)
!46 = !DILocation(line: 5, column: 49, scope: !25)
!47 = !DILocation(line: 5, column: 20, scope: !26)
!48 = !DILocation(line: 5, column: 16, scope: !26)
!49 = !DILocation(line: 5, column: 3, scope: !23)
!50 = distinct !{!50, !49, !51, !39, !40}
!51 = !DILocation(line: 5, column: 66, scope: !23)
!52 = !DISubprogram(name: "cq_theta_si32", scope: !53, file: !53, line: 38, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!53 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!54 = !DISubroutineType(types: !55)
!55 = !{!13, !13, !56}
!56 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!57 = !DISubprogram(name: "cq_measure_si32", scope: !53, file: !53, line: 83, type: !58, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!58 = !DISubroutineType(types: !59)
!59 = !{!13, !13}
