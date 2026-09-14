; ModuleID = 'src/ob1c_guarded_once_measure_after.c'
source_filename = "src/ob1c_guarded_once_measure_after.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !20
    #dbg_value(i32 %1, !15, !DIExpression(), !21)
    #dbg_value(i32 0, !16, !DIExpression(), !21)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
    #dbg_value(i32 0, !18, !DIExpression(), !22)
  br label %5, !dbg !23

2:                                                ; preds = %14
  %3 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !24
  %4 = add nsw i32 %3, %16, !dbg !25
  ret i32 %4, !dbg !26

5:                                                ; preds = %0, %14
  %6 = phi i32 [ 0, %0 ], [ %17, %14 ]
  %7 = phi i32 [ 0, %0 ], [ %16, %14 ]
  %8 = phi i32 [ 0, %0 ], [ %15, %14 ]
    #dbg_value(i32 %6, !18, !DIExpression(), !22)
    #dbg_value(i32 %7, !17, !DIExpression(), !21)
    #dbg_value(i32 %8, !16, !DIExpression(), !21)
  %9 = icmp eq i32 %6, 0, !dbg !27
  br i1 %9, label %10, label %12, !dbg !31

10:                                               ; preds = %5
  %11 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 1.000000e-01) #2, !dbg !32
    #dbg_value(i32 %11, !16, !DIExpression(), !21)
  br label %14, !dbg !33

12:                                               ; preds = %5
  %13 = add nsw i32 %7, 1, !dbg !34
    #dbg_value(i32 %13, !17, !DIExpression(), !21)
  br label %14

14:                                               ; preds = %10, %12
  %15 = phi i32 [ %11, %10 ], [ %8, %12 ], !dbg !21
  %16 = phi i32 [ %7, %10 ], [ %13, %12 ], !dbg !21
    #dbg_value(i32 %16, !17, !DIExpression(), !21)
    #dbg_value(i32 %15, !16, !DIExpression(), !21)
  %17 = add nuw nsw i32 %6, 1, !dbg !35
    #dbg_value(i32 %17, !18, !DIExpression(), !22)
  %18 = icmp eq i32 %17, 3, !dbg !36
  br i1 %18, label %2, label %5, !dbg !23, !llvm.loop !37
}

declare !dbg !41 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !46 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/ob1c_guarded_once_measure_after.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "933d7f65651b89c60f6164fcfa3873e9")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "b", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!18 = !DILocalVariable(name: "i", scope: !19, file: !8, line: 4, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!20 = !DILocation(line: 3, column: 23, scope: !10)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 0, scope: !19)
!23 = !DILocation(line: 4, column: 3, scope: !19)
!24 = !DILocation(line: 5, column: 12, scope: !10)
!25 = !DILocation(line: 5, column: 11, scope: !10)
!26 = !DILocation(line: 5, column: 3, scope: !10)
!27 = !DILocation(line: 4, column: 29, scope: !28)
!28 = distinct !DILexicalBlock(scope: !29, file: !8, line: 4, column: 28)
!29 = distinct !DILexicalBlock(scope: !30, file: !8, line: 4, column: 23)
!30 = distinct !DILexicalBlock(scope: !19, file: !8, line: 4, column: 3)
!31 = !DILocation(line: 4, column: 28, scope: !29)
!32 = !DILocation(line: 4, column: 36, scope: !28)
!33 = !DILocation(line: 4, column: 34, scope: !28)
!34 = !DILocation(line: 4, column: 59, scope: !28)
!35 = !DILocation(line: 4, column: 20, scope: !30)
!36 = !DILocation(line: 4, column: 16, scope: !30)
!37 = distinct !{!37, !23, !38, !39, !40}
!38 = !DILocation(line: 4, column: 64, scope: !19)
!39 = !{!"llvm.loop.mustprogress"}
!40 = !{!"llvm.loop.unroll.disable"}
!41 = !DISubprogram(name: "cq_theta_si32", scope: !42, file: !42, line: 38, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!43 = !DISubroutineType(types: !44)
!44 = !{!13, !13, !45}
!45 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!46 = !DISubprogram(name: "cq_measure_si32", scope: !42, file: !42, line: 83, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DISubroutineType(types: !48)
!48 = !{!13, !13}
