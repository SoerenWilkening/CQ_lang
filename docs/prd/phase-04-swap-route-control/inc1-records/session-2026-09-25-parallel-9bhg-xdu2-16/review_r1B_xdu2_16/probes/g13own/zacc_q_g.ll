; ModuleID = 'zacc_q.c'
source_filename = "zacc_q.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !18, !DIExpression(), !20)
    #dbg_value(ptr %1, !19, !DIExpression(), !20)
  %3 = add nsw i32 %0, 2, !dbg !21
  %4 = tail call fastcc i32 @slice(i32 noundef %3), !dbg !22
  ret i32 %4, !dbg !23
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 !dbg !24 {
    #dbg_value(i32 %0, !28, !DIExpression(), !34)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01) #3, !dbg !35
    #dbg_value(i32 %2, !29, !DIExpression(), !34)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #3, !dbg !36
    #dbg_value(i32 %3, !30, !DIExpression(), !34)
    #dbg_value(i32 0, !31, !DIExpression(), !34)
    #dbg_value(i32 0, !32, !DIExpression(), !37)
  %4 = icmp sgt i32 %0, 0, !dbg !38
  br i1 %4, label %5, label %9, !dbg !40

5:                                                ; preds = %1
  %6 = icmp sgt i32 %2, 1
  %7 = icmp slt i32 %3, 5
  %8 = and i1 %6, %7
  br label %17, !dbg !40

9:                                                ; preds = %17, %1
  %10 = phi i32 [ 0, %1 ], [ %21, %17 ], !dbg !34
  %11 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 0x3FE6666666666666) #3, !dbg !41
    #dbg_value(i32 %11, !29, !DIExpression(), !34)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3, !dbg !42
  %13 = tail call i32 @cq_measure_si32(i32 noundef %3) #3, !dbg !43
  %14 = add nsw i32 %13, %12, !dbg !44
  %15 = tail call i32 @cq_measure_si32(i32 noundef %10) #3, !dbg !45
  %16 = add nsw i32 %14, %15, !dbg !46
  ret i32 %16, !dbg !47

17:                                               ; preds = %5, %17
  %18 = phi i32 [ 0, %5 ], [ %22, %17 ]
  %19 = phi i32 [ 0, %5 ], [ %21, %17 ]
    #dbg_value(i32 %18, !32, !DIExpression(), !37)
    #dbg_value(i32 %19, !31, !DIExpression(), !34)
  %20 = add nsw i32 %19, 3
  %21 = select i1 %8, i32 %20, i32 %19, !dbg !48
    #dbg_value(i32 %21, !31, !DIExpression(), !34)
  %22 = add nuw nsw i32 %18, 1, !dbg !49
    #dbg_value(i32 %22, !32, !DIExpression(), !37)
  %23 = icmp eq i32 %22, %0, !dbg !38
  br i1 %23, label %9, label %17, !dbg !40, !llvm.loop !50
}

declare !dbg !54 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare !dbg !59 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!8 = !DIFile(filename: "zacc_q.c", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/review_r1B_xdu2_16/probes/g13own", checksumkind: CSK_MD5, checksum: "8bc4b628a50cddd4dc9aa2b9aadb22cc")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 10, type: !11, scopeLine: 10, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13, !14}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!15 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !16, size: 64)
!16 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!17 = !{!18, !19}
!18 = !DILocalVariable(name: "argc", arg: 1, scope: !10, file: !8, line: 10, type: !13)
!19 = !DILocalVariable(name: "argv", arg: 2, scope: !10, file: !8, line: 10, type: !14)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 10, column: 65, scope: !10)
!22 = !DILocation(line: 10, column: 54, scope: !10)
!23 = !DILocation(line: 10, column: 47, scope: !10)
!24 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 1, type: !25, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !27)
!25 = !DISubroutineType(types: !26)
!26 = !{!13, !13}
!27 = !{!28, !29, !30, !31, !32}
!28 = !DILocalVariable(name: "n", arg: 1, scope: !24, file: !8, line: 1, type: !13)
!29 = !DILocalVariable(name: "q", scope: !24, file: !8, line: 2, type: !13)
!30 = !DILocalVariable(name: "r", scope: !24, file: !8, line: 3, type: !13)
!31 = !DILocalVariable(name: "a", scope: !24, file: !8, line: 4, type: !13)
!32 = !DILocalVariable(name: "i", scope: !33, file: !8, line: 5, type: !13)
!33 = distinct !DILexicalBlock(scope: !24, file: !8, line: 5, column: 5)
!34 = !DILocation(line: 0, scope: !24)
!35 = !DILocation(line: 2, column: 13, scope: !24)
!36 = !DILocation(line: 3, column: 13, scope: !24)
!37 = !DILocation(line: 0, scope: !33)
!38 = !DILocation(line: 5, column: 23, scope: !39)
!39 = distinct !DILexicalBlock(scope: !33, file: !8, line: 5, column: 5)
!40 = !DILocation(line: 5, column: 5, scope: !33)
!41 = !DILocation(line: 7, column: 9, scope: !24)
!42 = !DILocation(line: 8, column: 12, scope: !24)
!43 = !DILocation(line: 8, column: 28, scope: !24)
!44 = !DILocation(line: 8, column: 26, scope: !24)
!45 = !DILocation(line: 8, column: 44, scope: !24)
!46 = !DILocation(line: 8, column: 42, scope: !24)
!47 = !DILocation(line: 8, column: 5, scope: !24)
!48 = !DILocation(line: 6, column: 13, scope: !39)
!49 = !DILocation(line: 5, column: 28, scope: !39)
!50 = distinct !{!50, !40, !51, !52, !53}
!51 = !DILocation(line: 6, column: 37, scope: !33)
!52 = !{!"llvm.loop.mustprogress"}
!53 = !{!"llvm.loop.unroll.disable"}
!54 = !DISubprogram(name: "cq_theta_si32", scope: !55, file: !55, line: 38, type: !56, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!56 = !DISubroutineType(types: !57)
!57 = !{!13, !13, !58}
!58 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!59 = !DISubprogram(name: "cq_measure_si32", scope: !55, file: !55, line: 83, type: !25, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
