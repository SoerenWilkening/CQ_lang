; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/n4_cascade.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/n4_cascade.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !15, !DIExpression(), !21)
    #dbg_value(i8 0, !16, !DIExpression(), !21)
    #dbg_value(i8 0, !18, !DIExpression(), !21)
    #dbg_value(i8 0, !19, !DIExpression(), !21)
    #dbg_value(i8 0, !20, !DIExpression(), !21)
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i1 %1, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
  %2 = select i1 %1, i32 2, i32 5, !dbg !23
    #dbg_value(i32 %2, !15, !DIExpression(), !21)
  br i1 %1, label %5, label %3, !dbg !24

3:                                                ; preds = %0
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !25
    #dbg_value(i1 %4, !18, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
  br label %5, !dbg !28

5:                                                ; preds = %3, %0
  %6 = phi i1 [ %4, %3 ], [ false, %0 ], !dbg !21
    #dbg_value(i8 poison, !18, !DIExpression(), !21)
  %7 = add nsw i32 %2, -3
  %8 = select i1 %6, i32 %7, i32 %2, !dbg !29
    #dbg_value(i32 %8, !15, !DIExpression(), !21)
  %9 = icmp sgt i32 %8, 2, !dbg !30
  br i1 %9, label %10, label %12, !dbg !32

10:                                               ; preds = %5
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !33
    #dbg_value(i1 %11, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
  br label %12, !dbg !35

12:                                               ; preds = %10, %5
  %13 = phi i1 [ %11, %10 ], [ false, %5 ], !dbg !21
    #dbg_value(i8 poison, !19, !DIExpression(), !21)
  %14 = add nsw i32 %8, -3
  %15 = select i1 %13, i32 %14, i32 %8, !dbg !36
    #dbg_value(i32 %15, !15, !DIExpression(), !21)
  %16 = icmp sgt i32 %15, 2, !dbg !37
  br i1 %16, label %17, label %19, !dbg !39

17:                                               ; preds = %12
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !40
    #dbg_value(i1 %18, !20, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !21)
  br label %19, !dbg !42

19:                                               ; preds = %17, %12
  %20 = phi i1 [ %18, %17 ], [ false, %12 ], !dbg !21
    #dbg_value(i8 poison, !20, !DIExpression(), !21)
  %21 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2, !dbg !43
  %22 = zext i1 %21 to i32, !dbg !43
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6) #2, !dbg !44
  %24 = zext i1 %23 to i32, !dbg !44
  %25 = add nuw nsw i32 %24, %22, !dbg !45
  %26 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13) #2, !dbg !46
  %27 = zext i1 %26 to i32, !dbg !46
  %28 = add nuw nsw i32 %25, %27, !dbg !47
  %29 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %20) #2, !dbg !48
  %30 = zext i1 %29 to i32, !dbg !48
  %31 = add nuw nsw i32 %28, %30, !dbg !49
  %32 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !50
  %33 = add nsw i32 %31, %32, !dbg !51
  ret i32 %33, !dbg !52
}

declare !dbg !53 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !58 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !61 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/n4_cascade.c", directory: "/Users/sorenwilkening/Desktop/CQ_f2phi", checksumkind: CSK_MD5, checksum: "0032d4df21244a83f2871f0253aa0467")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !18, !19, !20}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 5, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocalVariable(name: "b1", scope: !10, file: !8, line: 5, type: !17)
!19 = !DILocalVariable(name: "b2", scope: !10, file: !8, line: 5, type: !17)
!20 = !DILocalVariable(name: "b3", scope: !10, file: !8, line: 5, type: !17)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 6, column: 10, scope: !10)
!23 = !DILocation(line: 7, column: 9, scope: !10)
!24 = !DILocation(line: 8, column: 9, scope: !10)
!25 = !DILocation(line: 8, column: 24, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !8, line: 8, column: 17)
!27 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 9)
!28 = !DILocation(line: 8, column: 43, scope: !26)
!29 = !DILocation(line: 9, column: 9, scope: !10)
!30 = !DILocation(line: 10, column: 11, scope: !31)
!31 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 9)
!32 = !DILocation(line: 10, column: 9, scope: !10)
!33 = !DILocation(line: 10, column: 24, scope: !34)
!34 = distinct !DILexicalBlock(scope: !31, file: !8, line: 10, column: 17)
!35 = !DILocation(line: 10, column: 43, scope: !34)
!36 = !DILocation(line: 11, column: 9, scope: !10)
!37 = !DILocation(line: 12, column: 11, scope: !38)
!38 = distinct !DILexicalBlock(scope: !10, file: !8, line: 12, column: 9)
!39 = !DILocation(line: 12, column: 9, scope: !10)
!40 = !DILocation(line: 12, column: 24, scope: !41)
!41 = distinct !DILexicalBlock(scope: !38, file: !8, line: 12, column: 17)
!42 = !DILocation(line: 12, column: 43, scope: !41)
!43 = !DILocation(line: 13, column: 12, scope: !10)
!44 = !DILocation(line: 13, column: 29, scope: !10)
!45 = !DILocation(line: 13, column: 27, scope: !10)
!46 = !DILocation(line: 13, column: 46, scope: !10)
!47 = !DILocation(line: 13, column: 44, scope: !10)
!48 = !DILocation(line: 13, column: 63, scope: !10)
!49 = !DILocation(line: 13, column: 61, scope: !10)
!50 = !DILocation(line: 13, column: 80, scope: !10)
!51 = !DILocation(line: 13, column: 78, scope: !10)
!52 = !DILocation(line: 13, column: 5, scope: !10)
!53 = !DISubprogram(name: "cq_theta_i1", scope: !54, file: !54, line: 32, type: !55, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!54 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_f2phi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!55 = !DISubroutineType(types: !56)
!56 = !{!17, !17, !57}
!57 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!58 = !DISubprogram(name: "cq_measure_i1", scope: !54, file: !54, line: 77, type: !59, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!59 = !DISubroutineType(types: !60)
!60 = !{!17, !17}
!61 = !DISubprogram(name: "cq_measure_si32", scope: !54, file: !54, line: 83, type: !62, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!62 = !DISubroutineType(types: !63)
!63 = !{!13, !13}
