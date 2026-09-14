; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p4_sideways_guard.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p4_sideways_guard.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !16, !DIExpression(), !22)
    #dbg_value(i8 0, !17, !DIExpression(), !22)
    #dbg_value(i8 0, !19, !DIExpression(), !22)
    #dbg_value(i8 0, !20, !DIExpression(), !22)
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !23
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i32 poison, !16, !DIExpression(), !22)
    #dbg_value(i32 poison, !21, !DIExpression(), !22)
  br i1 %1, label %4, label %2, !dbg !26

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !27
    #dbg_value(i1 %3, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
  br label %4, !dbg !30

4:                                                ; preds = %2, %0
  %5 = phi i1 [ %3, %2 ], [ false, %0 ], !dbg !22
    #dbg_value(i8 poison, !19, !DIExpression(), !22)
    #dbg_value(i32 poison, !16, !DIExpression(), !22)
  br i1 %1, label %8, label %6, !dbg !31

6:                                                ; preds = %4
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !32
    #dbg_value(i1 %7, !20, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
  br label %8, !dbg !35

8:                                                ; preds = %6, %4
  %9 = phi i32 [ 5, %6 ], [ 2, %4 ], !dbg !22
  %10 = phi i1 [ %7, %6 ], [ false, %4 ], !dbg !22
    #dbg_value(i32 %9, !16, !DIExpression(), !22)
    #dbg_value(i32 %9, !21, !DIExpression(), !22)
  %11 = add nsw i32 %9, -3
  %12 = select i1 %5, i32 %11, i32 %9, !dbg !36
    #dbg_value(i32 %12, !16, !DIExpression(), !22)
    #dbg_value(i8 poison, !20, !DIExpression(), !22)
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !37
  %14 = zext i1 %13 to i32, !dbg !37
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2, !dbg !38
  %16 = zext i1 %15 to i32, !dbg !38
  %17 = add nuw nsw i32 %16, %14, !dbg !39
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10) #2, !dbg !40
  %19 = zext i1 %18 to i32, !dbg !40
  %20 = add nuw nsw i32 %17, %19, !dbg !41
  %21 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !42
  %22 = add nsw i32 %20, %21, !dbg !43
  ret i32 %22, !dbg !44
}

declare !dbg !45 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !50 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !53 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p4_sideways_guard.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "f7c3c6a47bbc481a2996861ef27a19f5")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !11, file: !11, line: 6, type: !12, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!11 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/review_r1_probes/c/p4_sideways_guard.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "f7c3c6a47bbc481a2996861ef27a19f5")
!12 = !DISubroutineType(types: !13)
!13 = !{!14}
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !{!16, !17, !19, !20, !21}
!16 = !DILocalVariable(name: "a", scope: !10, file: !11, line: 7, type: !14)
!17 = !DILocalVariable(name: "b0", scope: !10, file: !11, line: 8, type: !18)
!18 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!19 = !DILocalVariable(name: "b1", scope: !10, file: !11, line: 8, type: !18)
!20 = !DILocalVariable(name: "b2", scope: !10, file: !11, line: 8, type: !18)
!21 = !DILocalVariable(name: "pre", scope: !10, file: !11, line: 11, type: !14)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 9, column: 24, scope: !24)
!24 = distinct !DILexicalBlock(scope: !25, file: !11, line: 9, column: 17)
!25 = distinct !DILexicalBlock(scope: !10, file: !11, line: 9, column: 9)
!26 = !DILocation(line: 12, column: 9, scope: !10)
!27 = !DILocation(line: 12, column: 24, scope: !28)
!28 = distinct !DILexicalBlock(scope: !29, file: !11, line: 12, column: 17)
!29 = distinct !DILexicalBlock(scope: !10, file: !11, line: 12, column: 9)
!30 = !DILocation(line: 12, column: 43, scope: !28)
!31 = !DILocation(line: 14, column: 9, scope: !10)
!32 = !DILocation(line: 14, column: 26, scope: !33)
!33 = distinct !DILexicalBlock(scope: !34, file: !11, line: 14, column: 19)
!34 = distinct !DILexicalBlock(scope: !10, file: !11, line: 14, column: 9)
!35 = !DILocation(line: 14, column: 45, scope: !33)
!36 = !DILocation(line: 13, column: 9, scope: !10)
!37 = !DILocation(line: 15, column: 12, scope: !10)
!38 = !DILocation(line: 15, column: 27, scope: !10)
!39 = !DILocation(line: 15, column: 26, scope: !10)
!40 = !DILocation(line: 15, column: 42, scope: !10)
!41 = !DILocation(line: 15, column: 41, scope: !10)
!42 = !DILocation(line: 15, column: 57, scope: !10)
!43 = !DILocation(line: 15, column: 56, scope: !10)
!44 = !DILocation(line: 15, column: 5, scope: !10)
!45 = !DISubprogram(name: "cq_theta_i1", scope: !46, file: !46, line: 32, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!47 = !DISubroutineType(types: !48)
!48 = !{!18, !18, !49}
!49 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!50 = !DISubprogram(name: "cq_measure_i1", scope: !46, file: !46, line: 77, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DISubroutineType(types: !52)
!52 = !{!18, !18}
!53 = !DISubprogram(name: "cq_measure_si32", scope: !46, file: !46, line: 83, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!54 = !DISubroutineType(types: !55)
!55 = !{!14, !14}
