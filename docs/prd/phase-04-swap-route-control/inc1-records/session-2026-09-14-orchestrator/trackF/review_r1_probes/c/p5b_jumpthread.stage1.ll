; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p5b_jumpthread.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p5b_jumpthread.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2, !dbg !21
  %2 = icmp eq i32 %1, 0, !dbg !21
    #dbg_value(i1 %2, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i8 0, !18, !DIExpression(), !22)
    #dbg_value(i8 0, !19, !DIExpression(), !22)
    #dbg_value(i32 7, !20, !DIExpression(), !22)
  br i1 %2, label %5, label %3, !dbg !23

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !24
    #dbg_value(i1 %4, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
  br label %5, !dbg !27

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ false, %0 ], !dbg !22
    #dbg_value(i8 poison, !18, !DIExpression(), !22)
    #dbg_value(i32 poison, !20, !DIExpression(), !22)
  br i1 %6, label %9, label %7, !dbg !28

7:                                                ; preds = %5
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !29
    #dbg_value(i1 %8, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
  br label %9, !dbg !32

9:                                                ; preds = %7, %5
  %10 = phi i32 [ 9, %7 ], [ 1, %5 ], !dbg !22
  %11 = phi i1 [ %8, %7 ], [ false, %5 ], !dbg !22
    #dbg_value(i32 %10, !20, !DIExpression(), !22)
    #dbg_value(i8 poison, !19, !DIExpression(), !22)
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !33
  %13 = zext i1 %12 to i32, !dbg !33
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11) #2, !dbg !34
  %15 = zext i1 %14 to i32, !dbg !34
  %16 = add nuw nsw i32 %15, %13, !dbg !35
  %17 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !36
  %18 = add nsw i32 %16, %17, !dbg !37
  ret i32 %18, !dbg !38
}

declare !dbg !39 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !44 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !47 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !50 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p5b_jumpthread.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "9d3ab4fb895e367da8c1639e6960a6d6")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 7, type: !12, scopeLine: 7, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p5b_jumpthread.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "9d3ab4fb895e367da8c1639e6960a6d6")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !18, !19, !20}
!16 = !DILocalVariable(name: "q", scope: !10, file: !11, line: 8, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 9, type: !17)
!19 = !DILocalVariable(name: "b2", scope: !10, file: !11, line: 9, type: !17)
!20 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 10, type: !14)
!21 = !DILocation(line: 8, column: 14, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 11, column: 9, scope: !10)
!24 = !DILocation(line: 11, column: 19, scope: !25)
!25 = distinct !DILexicalBlock(scope: !26, file: !11, line: 11, column: 12)
!26 = distinct !DILexicalBlock(scope: !10, file: !11, line: 11, column: 9)
!27 = !DILocation(line: 11, column: 38, scope: !25)
!28 = !DILocation(line: 13, column: 9, scope: !10)
!29 = !DILocation(line: 13, column: 23, scope: !30)
!30 = distinct !DILexicalBlock(scope: !31, file: !11, line: 13, column: 16)
!31 = distinct !DILexicalBlock(scope: !10, file: !11, line: 13, column: 9)
!32 = !DILocation(line: 13, column: 42, scope: !30)
!33 = !DILocation(line: 14, column: 12, scope: !10)
!34 = !DILocation(line: 14, column: 27, scope: !10)
!35 = !DILocation(line: 14, column: 26, scope: !10)
!36 = !DILocation(line: 14, column: 42, scope: !10)
!37 = !DILocation(line: 14, column: 41, scope: !10)
!38 = !DILocation(line: 14, column: 5, scope: !10)
!39 = !DISubprogram(name: "cq_theta_si32", scope: !40, file: !40, line: 38, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!40 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!41 = !DISubroutineType(types: !42)
!42 = !{!14, !14, !43}
!43 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!44 = !DISubprogram(name: "cq_theta_i1", scope: !40, file: !40, line: 32, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DISubroutineType(types: !46)
!46 = !{!17, !17, !43}
!47 = !DISubprogram(name: "cq_measure_i1", scope: !40, file: !40, line: 77, type: !48, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!48 = !DISubroutineType(types: !49)
!49 = !{!17, !17}
!50 = !DISubprogram(name: "cq_measure_si32", scope: !40, file: !40, line: 83, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DISubroutineType(types: !52)
!52 = !{!14, !14}
