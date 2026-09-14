; ModuleID = 'src/rec1_recursive_reader.c'
source_filename = "src/rec1_recursive_reader.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #3, !dbg !16
    #dbg_value(i32 %1, !15, !DIExpression(), !17)
  %2 = tail call fastcc i32 @f(i32 noundef %1, i32 noundef 3), !dbg !18
  ret i32 %2, !dbg !19
}

declare !dbg !20 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @f(i32 noundef %0, i32 noundef %1) unnamed_addr #2 !dbg !25 {
  br label %3

3:                                                ; preds = %7, %2
  %4 = phi i32 [ 0, %2 ], [ %11, %7 ]
  %5 = phi i32 [ %1, %2 ], [ %10, %7 ]
    #dbg_value(i32 %0, !29, !DIExpression(), !32)
    #dbg_value(i32 %5, !30, !DIExpression(), !32)
  %6 = icmp slt i32 %5, 1, !dbg !33
  br i1 %6, label %12, label %7, !dbg !35

7:                                                ; preds = %3
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e-01) #3, !dbg !36
    #dbg_value(i32 %8, !31, !DIExpression(), !32)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #3, !dbg !37
  %10 = add nsw i32 %5, -1, !dbg !38
  %11 = add nsw i32 %4, %9, !dbg !39
  br label %3, !dbg !40

12:                                               ; preds = %3
  %13 = add nsw i32 %4, 0
  ret i32 %13, !dbg !41
}

declare !dbg !42 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
!8 = !DIFile(filename: "src/rec1_recursive_reader.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "9cec55abb71a21d4f73131318ba7c6b1")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocation(line: 6, column: 23, scope: !10)
!17 = !DILocation(line: 0, scope: !10)
!18 = !DILocation(line: 6, column: 47, scope: !10)
!19 = !DILocation(line: 6, column: 40, scope: !10)
!20 = !DISubprogram(name: "cq_theta_si32", scope: !21, file: !21, line: 38, type: !22, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!21 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!22 = !DISubroutineType(types: !23)
!23 = !{!13, !13, !24}
!24 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!25 = distinct !DISubprogram(name: "f", scope: !8, file: !8, line: 4, type: !26, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !28)
!26 = !DISubroutineType(types: !27)
!27 = !{!13, !13, !13}
!28 = !{!29, !30, !31}
!29 = !DILocalVariable(name: "q", arg: 1, scope: !25, file: !8, line: 4, type: !13)
!30 = !DILocalVariable(name: "n", arg: 2, scope: !25, file: !8, line: 4, type: !13)
!31 = !DILocalVariable(name: "b", scope: !25, file: !8, line: 5, type: !13)
!32 = !DILocation(line: 0, scope: !25)
!33 = !DILocation(line: 4, column: 59, scope: !34)
!34 = distinct !DILexicalBlock(scope: !25, file: !8, line: 4, column: 58)
!35 = !DILocation(line: 4, column: 58, scope: !25)
!36 = !DILocation(line: 5, column: 9, scope: !25)
!37 = !DILocation(line: 5, column: 33, scope: !25)
!38 = !DILocation(line: 5, column: 52, scope: !25)
!39 = !DILocation(line: 5, column: 46, scope: !25)
!40 = !DILocation(line: 5, column: 47, scope: !25)
!41 = !DILocation(line: 5, column: 57, scope: !25)
!42 = !DISubprogram(name: "cq_measure_si32", scope: !21, file: !21, line: 83, type: !43, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DISubroutineType(types: !44)
!44 = !{!13, !13}
