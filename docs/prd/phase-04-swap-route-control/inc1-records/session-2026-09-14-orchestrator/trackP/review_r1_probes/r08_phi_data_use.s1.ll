; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r08_phi_data_use.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r08_phi_data_use.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !13 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #2, !dbg !21
    #dbg_value(i32 %1, !17, !DIExpression(), !22)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !23
    #dbg_value(i1 %2, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i8 0, !19, !DIExpression(), !22)
  br i1 %2, label %3, label %5, !dbg !24

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !25
    #dbg_value(i1 %4, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
  br label %5, !dbg !28

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ false, %0 ], !dbg !22
    #dbg_value(i8 poison, !19, !DIExpression(), !22)
  %7 = icmp sgt i32 %1, 3
  %8 = select i1 %6, i1 %7, i1 false, !dbg !29
  br i1 %8, label %9, label %10, !dbg !29

9:                                                ; preds = %5
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !31
  br label %10, !dbg !31

10:                                               ; preds = %9, %5
  %11 = zext i1 %6 to i32, !dbg !32
  %12 = add nsw i32 %1, %11, !dbg !33
    #dbg_value(i32 %12, !20, !DIExpression(), !22)
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #2, !dbg !34
  %14 = zext i1 %13 to i32, !dbg !34
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !35
  %16 = zext i1 %15 to i32, !dbg !35
  %17 = add nuw nsw i32 %16, %14, !dbg !36
  %18 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !37
  %19 = add nsw i32 %17, %18, !dbg !38
  ret i32 %19, !dbg !39
}

declare !dbg !40 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !45 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !48 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !51 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !54 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!12}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r08_phi_data_use.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "489ba4b9675bc928e73517437b6d6768")
!9 = !{!10, !11}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!12 = !{!"Homebrew clang version 19.1.7"}
!13 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 6, type: !14, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!14 = !DISubroutineType(types: !15)
!15 = !{!11}
!16 = !{!17, !18, !19, !20}
!17 = !DILocalVariable(name: "q", scope: !13, file: !8, line: 7, type: !11)
!18 = !DILocalVariable(name: "b0", scope: !13, file: !8, line: 8, type: !10)
!19 = !DILocalVariable(name: "b1", scope: !13, file: !8, line: 9, type: !10)
!20 = !DILocalVariable(name: "z", scope: !13, file: !8, line: 12, type: !11)
!21 = !DILocation(line: 7, column: 13, scope: !13)
!22 = !DILocation(line: 0, scope: !13)
!23 = !DILocation(line: 8, column: 15, scope: !13)
!24 = !DILocation(line: 10, column: 9, scope: !13)
!25 = !DILocation(line: 10, column: 20, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !8, line: 10, column: 13)
!27 = distinct !DILexicalBlock(scope: !13, file: !8, line: 10, column: 9)
!28 = !DILocation(line: 10, column: 39, scope: !26)
!29 = !DILocation(line: 11, column: 12, scope: !30)
!30 = distinct !DILexicalBlock(scope: !13, file: !8, line: 11, column: 9)
!31 = !DILocation(line: 11, column: 22, scope: !30)
!32 = !DILocation(line: 12, column: 13, scope: !13)
!33 = !DILocation(line: 12, column: 21, scope: !13)
!34 = !DILocation(line: 13, column: 12, scope: !13)
!35 = !DILocation(line: 13, column: 29, scope: !13)
!36 = !DILocation(line: 13, column: 27, scope: !13)
!37 = !DILocation(line: 13, column: 46, scope: !13)
!38 = !DILocation(line: 13, column: 44, scope: !13)
!39 = !DILocation(line: 13, column: 5, scope: !13)
!40 = !DISubprogram(name: "cq_theta_si32", scope: !41, file: !41, line: 38, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!41 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!42 = !DISubroutineType(types: !43)
!43 = !{!11, !11, !44}
!44 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!45 = !DISubprogram(name: "cq_theta_i1", scope: !41, file: !41, line: 32, type: !46, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DISubroutineType(types: !47)
!47 = !{!10, !10, !44}
!48 = !DISubprogram(name: "cq_phi", scope: !41, file: !41, line: 73, type: !49, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!49 = !DISubroutineType(types: !50)
!50 = !{null, !44}
!51 = !DISubprogram(name: "cq_measure_i1", scope: !41, file: !41, line: 77, type: !52, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!52 = !DISubroutineType(types: !53)
!53 = !{!10, !10}
!54 = !DISubprogram(name: "cq_measure_si32", scope: !41, file: !41, line: 83, type: !55, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = !DISubroutineType(types: !56)
!56 = !{!11, !11}
