; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/w3_runtime_a.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/w3_runtime_a.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !18, !DIExpression(), !25)
    #dbg_value(ptr %1, !19, !DIExpression(), !25)
    #dbg_value(i32 %0, !20, !DIExpression(DW_OP_plus_uconst, 4, DW_OP_stack_value), !25)
    #dbg_value(i8 0, !21, !DIExpression(), !25)
    #dbg_value(i8 0, !23, !DIExpression(), !25)
    #dbg_value(i8 0, !24, !DIExpression(), !25)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !26
    #dbg_value(i1 %3, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !25)
  %4 = select i1 %3, i32 1, i32 4, !dbg !27
  %5 = add nsw i32 %4, %0, !dbg !27
    #dbg_value(i32 %5, !20, !DIExpression(), !25)
  %6 = icmp sgt i32 %5, 2, !dbg !28
  br i1 %6, label %7, label %9, !dbg !30

7:                                                ; preds = %2
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !31
    #dbg_value(i1 %8, !23, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !25)
  br label %9, !dbg !33

9:                                                ; preds = %7, %2
  %10 = phi i1 [ %8, %7 ], [ false, %2 ], !dbg !25
    #dbg_value(i8 poison, !23, !DIExpression(), !25)
  %11 = add nsw i32 %5, -3
  %12 = select i1 %10, i32 %11, i32 %5, !dbg !34
    #dbg_value(i32 %12, !20, !DIExpression(), !25)
  %13 = icmp sgt i32 %12, 2, !dbg !35
  br i1 %13, label %14, label %16, !dbg !37

14:                                               ; preds = %9
  %15 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !38
    #dbg_value(i1 %15, !24, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !25)
  br label %16, !dbg !40

16:                                               ; preds = %14, %9
  %17 = phi i1 [ %15, %14 ], [ false, %9 ], !dbg !25
    #dbg_value(i8 poison, !24, !DIExpression(), !25)
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %3) #2, !dbg !41
  %19 = zext i1 %18 to i32, !dbg !41
  %20 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10) #2, !dbg !42
  %21 = zext i1 %20 to i32, !dbg !42
  %22 = add nuw nsw i32 %21, %19, !dbg !43
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %17) #2, !dbg !44
  %24 = zext i1 %23 to i32, !dbg !44
  %25 = add nuw nsw i32 %22, %24, !dbg !45
  %26 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !46
  %27 = add nsw i32 %25, %26, !dbg !47
  ret i32 %27, !dbg !48
}

declare !dbg !49 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !54 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/w3_runtime_a.c", directory: "/Users/sorenwilkening/Desktop/CQ_f2phi", checksumkind: CSK_MD5, checksum: "eaba654824f53b9a8e143d34c6ecd121")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13, !14}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!15 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !16, size: 64)
!16 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!17 = !{!18, !19, !20, !21, !23, !24}
!18 = !DILocalVariable(name: "argc", arg: 1, scope: !10, file: !8, line: 6, type: !13)
!19 = !DILocalVariable(name: "argv", arg: 2, scope: !10, file: !8, line: 6, type: !14)
!20 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 8, type: !13)
!21 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 9, type: !22)
!22 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!23 = !DILocalVariable(name: "b1", scope: !10, file: !8, line: 9, type: !22)
!24 = !DILocalVariable(name: "b2", scope: !10, file: !8, line: 9, type: !22)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 10, column: 10, scope: !10)
!27 = !DILocation(line: 11, column: 9, scope: !10)
!28 = !DILocation(line: 12, column: 11, scope: !29)
!29 = distinct !DILexicalBlock(scope: !10, file: !8, line: 12, column: 9)
!30 = !DILocation(line: 12, column: 9, scope: !10)
!31 = !DILocation(line: 12, column: 24, scope: !32)
!32 = distinct !DILexicalBlock(scope: !29, file: !8, line: 12, column: 17)
!33 = !DILocation(line: 12, column: 43, scope: !32)
!34 = !DILocation(line: 13, column: 9, scope: !10)
!35 = !DILocation(line: 14, column: 11, scope: !36)
!36 = distinct !DILexicalBlock(scope: !10, file: !8, line: 14, column: 9)
!37 = !DILocation(line: 14, column: 9, scope: !10)
!38 = !DILocation(line: 14, column: 24, scope: !39)
!39 = distinct !DILexicalBlock(scope: !36, file: !8, line: 14, column: 17)
!40 = !DILocation(line: 14, column: 43, scope: !39)
!41 = !DILocation(line: 15, column: 12, scope: !10)
!42 = !DILocation(line: 15, column: 29, scope: !10)
!43 = !DILocation(line: 15, column: 27, scope: !10)
!44 = !DILocation(line: 15, column: 46, scope: !10)
!45 = !DILocation(line: 15, column: 44, scope: !10)
!46 = !DILocation(line: 15, column: 63, scope: !10)
!47 = !DILocation(line: 15, column: 61, scope: !10)
!48 = !DILocation(line: 15, column: 5, scope: !10)
!49 = !DISubprogram(name: "cq_theta_i1", scope: !50, file: !50, line: 32, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!50 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_f2phi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!51 = !DISubroutineType(types: !52)
!52 = !{!22, !22, !53}
!53 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!54 = !DISubprogram(name: "cq_measure_i1", scope: !50, file: !50, line: 77, type: !55, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = !DISubroutineType(types: !56)
!56 = !{!22, !22}
!57 = !DISubprogram(name: "cq_measure_si32", scope: !50, file: !50, line: 83, type: !58, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!58 = !DISubroutineType(types: !59)
!59 = !{!13, !13}
