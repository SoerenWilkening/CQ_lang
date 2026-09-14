; ModuleID = './w2a_twoloop_passonly.c'
source_filename = "./w2a_twoloop_passonly.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
    #dbg_value(i32 0, !18, !DIExpression(), !31)
    #dbg_value(i32 0, !19, !DIExpression(), !32)
  br label %1, !dbg !33

1:                                                ; preds = %0, %8
  %2 = phi i32 [ 0, %0 ], [ %14, %8 ]
  %3 = phi i32 [ 0, %0 ], [ %15, %8 ]
    #dbg_value(i32 %2, !18, !DIExpression(), !31)
    #dbg_value(i32 %3, !19, !DIExpression(), !32)
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2, !dbg !34
    #dbg_value(i1 %4, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !35)
  %5 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2, !dbg !36
    #dbg_value(i32 %5, !24, !DIExpression(), !35)
  br i1 %4, label %6, label %8, !dbg !37

6:                                                ; preds = %1
  %7 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 2.000000e-01) #2, !dbg !38
    #dbg_value(i32 %7, !24, !DIExpression(), !35)
  br label %8, !dbg !40

8:                                                ; preds = %6, %1
  %9 = phi i32 [ %7, %6 ], [ %5, %1 ], !dbg !35
    #dbg_value(i32 %9, !24, !DIExpression(), !35)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !41
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #2, !dbg !42
  %12 = zext i1 %11 to i32, !dbg !42
  %13 = add i32 %10, %2, !dbg !43
  %14 = add i32 %13, %12, !dbg !44
    #dbg_value(i32 %14, !18, !DIExpression(), !31)
  %15 = add nuw nsw i32 %3, 1, !dbg !45
    #dbg_value(i32 %15, !19, !DIExpression(), !32)
  %16 = icmp eq i32 %3, 0, !dbg !46
  br i1 %16, label %1, label %18, !dbg !33, !llvm.loop !47

17:                                               ; preds = %25
  ret i32 %31, !dbg !51

18:                                               ; preds = %8, %25
  %19 = phi i32 [ %31, %25 ], [ %14, %8 ]
  %20 = phi i32 [ %32, %25 ], [ 0, %8 ]
    #dbg_value(i32 %19, !18, !DIExpression(), !31)
    #dbg_value(i32 %20, !25, !DIExpression(), !52)
  %21 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01) #2, !dbg !53
    #dbg_value(i1 %21, !27, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !54)
  %22 = tail call i32 @cq_theta_si32(i32 noundef 9, double noundef 3.500000e-01) #2, !dbg !55
    #dbg_value(i32 %22, !30, !DIExpression(), !54)
  br i1 %21, label %23, label %25, !dbg !56

23:                                               ; preds = %18
  %24 = tail call i32 @cq_theta_si32(i32 noundef %22, double noundef 3.000000e-01) #2, !dbg !57
    #dbg_value(i32 %24, !30, !DIExpression(), !54)
  br label %25, !dbg !59

25:                                               ; preds = %23, %18
  %26 = phi i32 [ %24, %23 ], [ %22, %18 ], !dbg !54
    #dbg_value(i32 %26, !30, !DIExpression(), !54)
  %27 = tail call i32 @cq_measure_si32(i32 noundef %26) #2, !dbg !60
  %28 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %21) #2, !dbg !61
  %29 = zext i1 %28 to i32, !dbg !61
  %30 = add i32 %27, %19, !dbg !62
  %31 = add i32 %30, %29, !dbg !63
    #dbg_value(i32 %31, !18, !DIExpression(), !31)
  %32 = add nuw nsw i32 %20, 1, !dbg !64
    #dbg_value(i32 %32, !25, !DIExpression(), !52)
  %33 = icmp eq i32 %20, 0, !dbg !65
  br i1 %33, label %18, label %17, !dbg !66, !llvm.loop !67
}

declare !dbg !69 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !74 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !77 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare !dbg !80 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !83 {
  %1 = tail call i32 @slice(), !dbg !84
  ret i32 %1, !dbg !85
}

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
!8 = !DIFile(filename: "w2a_twoloop_passonly.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "85338d74a16711bcb4a11a6a29f3bbd6")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 4, type: !14, scopeLine: 4, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2a_twoloop_passonly.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "85338d74a16711bcb4a11a6a29f3bbd6")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !21, !24, !25, !27, !30}
!18 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 5, type: !16)
!19 = !DILocalVariable(name: "k", scope: !20, file: !13, line: 6, type: !16)
!20 = distinct !DILexicalBlock(scope: !12, file: !13, line: 6, column: 5)
!21 = !DILocalVariable(name: "t", scope: !22, file: !13, line: 7, type: !10)
!22 = distinct !DILexicalBlock(scope: !23, file: !13, line: 6, column: 33)
!23 = distinct !DILexicalBlock(scope: !20, file: !13, line: 6, column: 5)
!24 = !DILocalVariable(name: "r", scope: !22, file: !13, line: 8, type: !16)
!25 = !DILocalVariable(name: "k", scope: !26, file: !13, line: 12, type: !16)
!26 = distinct !DILexicalBlock(scope: !12, file: !13, line: 12, column: 5)
!27 = !DILocalVariable(name: "t2", scope: !28, file: !13, line: 13, type: !10)
!28 = distinct !DILexicalBlock(scope: !29, file: !13, line: 12, column: 33)
!29 = distinct !DILexicalBlock(scope: !26, file: !13, line: 12, column: 5)
!30 = !DILocalVariable(name: "r2", scope: !28, file: !13, line: 14, type: !16)
!31 = !DILocation(line: 0, scope: !12)
!32 = !DILocation(line: 0, scope: !20)
!33 = !DILocation(line: 6, column: 5, scope: !20)
!34 = !DILocation(line: 7, column: 18, scope: !22)
!35 = !DILocation(line: 0, scope: !22)
!36 = !DILocation(line: 8, column: 17, scope: !22)
!37 = !DILocation(line: 9, column: 13, scope: !22)
!38 = !DILocation(line: 9, column: 20, scope: !39)
!39 = distinct !DILexicalBlock(scope: !22, file: !13, line: 9, column: 13)
!40 = !DILocation(line: 9, column: 16, scope: !39)
!41 = !DILocation(line: 10, column: 14, scope: !22)
!42 = !DILocation(line: 10, column: 30, scope: !22)
!43 = !DILocation(line: 10, column: 28, scope: !22)
!44 = !DILocation(line: 10, column: 11, scope: !22)
!45 = !DILocation(line: 6, column: 28, scope: !23)
!46 = !DILocation(line: 6, column: 23, scope: !23)
!47 = distinct !{!47, !33, !48, !49, !50}
!48 = !DILocation(line: 11, column: 5, scope: !20)
!49 = !{!"llvm.loop.mustprogress"}
!50 = !{!"llvm.loop.unroll.disable"}
!51 = !DILocation(line: 18, column: 5, scope: !12)
!52 = !DILocation(line: 0, scope: !26)
!53 = !DILocation(line: 13, column: 19, scope: !28)
!54 = !DILocation(line: 0, scope: !28)
!55 = !DILocation(line: 14, column: 18, scope: !28)
!56 = !DILocation(line: 15, column: 13, scope: !28)
!57 = !DILocation(line: 15, column: 22, scope: !58)
!58 = distinct !DILexicalBlock(scope: !28, file: !13, line: 15, column: 13)
!59 = !DILocation(line: 15, column: 17, scope: !58)
!60 = !DILocation(line: 16, column: 14, scope: !28)
!61 = !DILocation(line: 16, column: 31, scope: !28)
!62 = !DILocation(line: 16, column: 29, scope: !28)
!63 = !DILocation(line: 16, column: 11, scope: !28)
!64 = !DILocation(line: 12, column: 28, scope: !29)
!65 = !DILocation(line: 12, column: 23, scope: !29)
!66 = !DILocation(line: 12, column: 5, scope: !26)
!67 = distinct !{!67, !66, !68, !49, !50}
!68 = !DILocation(line: 17, column: 5, scope: !26)
!69 = !DISubprogram(name: "cq_theta_i1", scope: !70, file: !70, line: 32, type: !71, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!70 = !DIFile(filename: "CQ_wx8g/include/CQ.h", directory: "/Users/sorenwilkening/Desktop", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!71 = !DISubroutineType(types: !72)
!72 = !{!10, !10, !73}
!73 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!74 = !DISubprogram(name: "cq_theta_si32", scope: !70, file: !70, line: 38, type: !75, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!75 = !DISubroutineType(types: !76)
!76 = !{!16, !16, !73}
!77 = !DISubprogram(name: "cq_measure_si32", scope: !70, file: !70, line: 83, type: !78, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!78 = !DISubroutineType(types: !79)
!79 = !{!16, !16}
!80 = !DISubprogram(name: "cq_measure_i1", scope: !70, file: !70, line: 77, type: !81, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!81 = !DISubroutineType(types: !82)
!82 = !{!10, !10}
!83 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 20, type: !14, scopeLine: 20, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!84 = !DILocation(line: 20, column: 25, scope: !83)
!85 = !DILocation(line: 20, column: 18, scope: !83)
