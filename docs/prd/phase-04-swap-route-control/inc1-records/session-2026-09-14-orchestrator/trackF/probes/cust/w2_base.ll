; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/w2.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/w2.c"
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
  %3 = icmp sgt i32 %0, -2, !dbg !26
  br i1 %3, label %4, label %6, !dbg !28

4:                                                ; preds = %2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !29
    #dbg_value(i1 %5, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !25)
  br label %6, !dbg !31

6:                                                ; preds = %4, %2
  %7 = phi i1 [ %5, %4 ], [ false, %2 ], !dbg !25
    #dbg_value(i8 poison, !21, !DIExpression(), !25)
  %8 = select i1 %7, i32 1, i32 4, !dbg !32
  %9 = add nsw i32 %8, %0, !dbg !32
    #dbg_value(i32 %9, !20, !DIExpression(), !25)
  %10 = icmp sgt i32 %9, 2, !dbg !33
  br i1 %10, label %11, label %13, !dbg !35

11:                                               ; preds = %6
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !36
    #dbg_value(i1 %12, !23, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !25)
  br label %13, !dbg !38

13:                                               ; preds = %11, %6
  %14 = phi i1 [ %12, %11 ], [ false, %6 ], !dbg !25
    #dbg_value(i8 poison, !23, !DIExpression(), !25)
  %15 = add nsw i32 %9, -3
  %16 = select i1 %14, i32 %15, i32 %9, !dbg !39
    #dbg_value(i32 %16, !20, !DIExpression(), !25)
  %17 = icmp sgt i32 %16, 2, !dbg !40
  br i1 %17, label %18, label %20, !dbg !42

18:                                               ; preds = %13
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !43
    #dbg_value(i1 %19, !24, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !25)
  br label %20, !dbg !45

20:                                               ; preds = %18, %13
  %21 = phi i1 [ %19, %18 ], [ false, %13 ], !dbg !25
    #dbg_value(i8 poison, !24, !DIExpression(), !25)
  %22 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #2, !dbg !46
  %23 = zext i1 %22 to i32, !dbg !46
  %24 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %14) #2, !dbg !47
  %25 = zext i1 %24 to i32, !dbg !47
  %26 = add nuw nsw i32 %25, %23, !dbg !48
  %27 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %21) #2, !dbg !49
  %28 = zext i1 %27 to i32, !dbg !49
  %29 = add nuw nsw i32 %26, %28, !dbg !50
  %30 = tail call i32 @cq_measure_si32(i32 noundef %16) #2, !dbg !51
  %31 = add nsw i32 %29, %30, !dbg !52
  ret i32 %31, !dbg !53
}

declare !dbg !54 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !59 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare !dbg !62 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackF/probes/c/w2.c", directory: "/Users/sorenwilkening/Desktop/CQ_f2phi", checksumkind: CSK_MD5, checksum: "3628d8533f9fca75f5c3295f2da6771a")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13, !14}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !15, size: 64)
!15 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !16, size: 64)
!16 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!17 = !{!18, !19, !20, !21, !23, !24}
!18 = !DILocalVariable(name: "argc", arg: 1, scope: !10, file: !8, line: 3, type: !13)
!19 = !DILocalVariable(name: "argv", arg: 2, scope: !10, file: !8, line: 3, type: !14)
!20 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 5, type: !13)
!21 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 6, type: !22)
!22 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!23 = !DILocalVariable(name: "b1", scope: !10, file: !8, line: 6, type: !22)
!24 = !DILocalVariable(name: "b2", scope: !10, file: !8, line: 6, type: !22)
!25 = !DILocation(line: 0, scope: !10)
!26 = !DILocation(line: 7, column: 11, scope: !27)
!27 = distinct !DILexicalBlock(scope: !10, file: !8, line: 7, column: 9)
!28 = !DILocation(line: 7, column: 9, scope: !10)
!29 = !DILocation(line: 7, column: 23, scope: !30)
!30 = distinct !DILexicalBlock(scope: !27, file: !8, line: 7, column: 16)
!31 = !DILocation(line: 7, column: 42, scope: !30)
!32 = !DILocation(line: 8, column: 9, scope: !10)
!33 = !DILocation(line: 9, column: 11, scope: !34)
!34 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 9)
!35 = !DILocation(line: 9, column: 9, scope: !10)
!36 = !DILocation(line: 9, column: 23, scope: !37)
!37 = distinct !DILexicalBlock(scope: !34, file: !8, line: 9, column: 16)
!38 = !DILocation(line: 9, column: 42, scope: !37)
!39 = !DILocation(line: 10, column: 9, scope: !10)
!40 = !DILocation(line: 11, column: 11, scope: !41)
!41 = distinct !DILexicalBlock(scope: !10, file: !8, line: 11, column: 9)
!42 = !DILocation(line: 11, column: 9, scope: !10)
!43 = !DILocation(line: 11, column: 23, scope: !44)
!44 = distinct !DILexicalBlock(scope: !41, file: !8, line: 11, column: 16)
!45 = !DILocation(line: 11, column: 42, scope: !44)
!46 = !DILocation(line: 12, column: 12, scope: !10)
!47 = !DILocation(line: 12, column: 29, scope: !10)
!48 = !DILocation(line: 12, column: 27, scope: !10)
!49 = !DILocation(line: 12, column: 46, scope: !10)
!50 = !DILocation(line: 12, column: 44, scope: !10)
!51 = !DILocation(line: 12, column: 63, scope: !10)
!52 = !DILocation(line: 12, column: 61, scope: !10)
!53 = !DILocation(line: 12, column: 5, scope: !10)
!54 = !DISubprogram(name: "cq_theta_i1", scope: !55, file: !55, line: 32, type: !56, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!55 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_f2phi", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!56 = !DISubroutineType(types: !57)
!57 = !{!22, !22, !58}
!58 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!59 = !DISubprogram(name: "cq_measure_i1", scope: !55, file: !55, line: 77, type: !60, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!60 = !DISubroutineType(types: !61)
!61 = !{!22, !22}
!62 = !DISubprogram(name: "cq_measure_si32", scope: !55, file: !55, line: 83, type: !63, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!63 = !DISubroutineType(types: !64)
!64 = !{!13, !13}
