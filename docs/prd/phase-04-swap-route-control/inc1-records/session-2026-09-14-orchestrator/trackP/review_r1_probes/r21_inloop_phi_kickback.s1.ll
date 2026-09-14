; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r21_inloop_phi_kickback.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r21_inloop_phi_kickback.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @main() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !21
    #dbg_value(i1 %1, !17, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
    #dbg_value(i8 0, !18, !DIExpression(), !22)
  br i1 %1, label %2, label %4, !dbg !23

2:                                                ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !24
    #dbg_value(i1 %3, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !22)
  br label %4, !dbg !27

4:                                                ; preds = %2, %0
  %5 = phi i1 [ %3, %2 ], [ false, %0 ], !dbg !22
    #dbg_value(i8 poison, !18, !DIExpression(), !22)
    #dbg_value(i32 0, !19, !DIExpression(), !28)
  br label %12, !dbg !29

6:                                                ; preds = %15
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !30
  %8 = zext i1 %7 to i32, !dbg !30
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2, !dbg !31
  %10 = zext i1 %9 to i32, !dbg !31
  %11 = add nuw nsw i32 %10, %8, !dbg !32
  ret i32 %11, !dbg !33

12:                                               ; preds = %4, %15
  %13 = phi i32 [ 0, %4 ], [ %16, %15 ]
    #dbg_value(i32 %13, !19, !DIExpression(), !28)
  br i1 %5, label %14, label %15, !dbg !34

14:                                               ; preds = %12
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !37
  br label %15, !dbg !37

15:                                               ; preds = %12, %14
  %16 = add nuw nsw i32 %13, 1, !dbg !39
    #dbg_value(i32 %16, !19, !DIExpression(), !28)
  %17 = icmp eq i32 %16, 3, !dbg !40
  br i1 %17, label %6, label %12, !dbg !29, !llvm.loop !41
}

declare !dbg !45 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !50 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !53 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!11}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes/r21_inloop_phi_kickback.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "ae1da8b2ff261e8c120b6fa634c5de0f")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 5, type: !13, scopeLine: 5, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !16)
!13 = !DISubroutineType(types: !14)
!14 = !{!15}
!15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!16 = !{!17, !18, !19}
!17 = !DILocalVariable(name: "b0", scope: !12, file: !8, line: 6, type: !10)
!18 = !DILocalVariable(name: "b1", scope: !12, file: !8, line: 7, type: !10)
!19 = !DILocalVariable(name: "i", scope: !20, file: !8, line: 9, type: !15)
!20 = distinct !DILexicalBlock(scope: !12, file: !8, line: 9, column: 5)
!21 = !DILocation(line: 6, column: 15, scope: !12)
!22 = !DILocation(line: 0, scope: !12)
!23 = !DILocation(line: 8, column: 9, scope: !12)
!24 = !DILocation(line: 8, column: 20, scope: !25)
!25 = distinct !DILexicalBlock(scope: !26, file: !8, line: 8, column: 13)
!26 = distinct !DILexicalBlock(scope: !12, file: !8, line: 8, column: 9)
!27 = !DILocation(line: 8, column: 39, scope: !25)
!28 = !DILocation(line: 0, scope: !20)
!29 = !DILocation(line: 9, column: 5, scope: !20)
!30 = !DILocation(line: 12, column: 12, scope: !12)
!31 = !DILocation(line: 12, column: 29, scope: !12)
!32 = !DILocation(line: 12, column: 27, scope: !12)
!33 = !DILocation(line: 12, column: 5, scope: !12)
!34 = !DILocation(line: 10, column: 13, scope: !35)
!35 = distinct !DILexicalBlock(scope: !36, file: !8, line: 9, column: 33)
!36 = distinct !DILexicalBlock(scope: !20, file: !8, line: 9, column: 5)
!37 = !DILocation(line: 10, column: 17, scope: !38)
!38 = distinct !DILexicalBlock(scope: !35, file: !8, line: 10, column: 13)
!39 = !DILocation(line: 9, column: 28, scope: !36)
!40 = !DILocation(line: 9, column: 23, scope: !36)
!41 = distinct !{!41, !29, !42, !43, !44}
!42 = !DILocation(line: 11, column: 5, scope: !20)
!43 = !{!"llvm.loop.mustprogress"}
!44 = !{!"llvm.loop.unroll.disable"}
!45 = !DISubprogram(name: "cq_theta_i1", scope: !46, file: !46, line: 32, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!47 = !DISubroutineType(types: !48)
!48 = !{!10, !10, !49}
!49 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!50 = !DISubprogram(name: "cq_phi", scope: !46, file: !46, line: 73, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DISubroutineType(types: !52)
!52 = !{null, !49}
!53 = !DISubprogram(name: "cq_measure_i1", scope: !46, file: !46, line: 77, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!54 = !DISubroutineType(types: !55)
!55 = !{!10, !10}
