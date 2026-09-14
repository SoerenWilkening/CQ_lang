; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !14 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3, !dbg !29
    #dbg_value(i32 %1, !20, !DIExpression(), !30)
    #dbg_value(i32 5, !21, !DIExpression(), !30)
  %2 = icmp sgt i32 %1, 5, !dbg !31
  br i1 %2, label %3, label %5, !dbg !33

3:                                                ; preds = %0
  %4 = tail call i32 @ext_f(i32 noundef 7) #3, !dbg !34
    #dbg_value(i32 %4, !21, !DIExpression(), !30)
  br label %5, !dbg !35

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 5, %0 ], !dbg !30
    #dbg_value(i32 %6, !21, !DIExpression(), !30)
    #dbg_value(i32 0, !22, !DIExpression(), !30)
    #dbg_value(i32 0, !23, !DIExpression(), !36)
  %7 = icmp sgt i32 %6, 50
  br label %11, !dbg !37

8:                                                ; preds = %21
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #3, !dbg !38
  %10 = add nsw i32 %9, %26, !dbg !39
  ret i32 %10, !dbg !40

11:                                               ; preds = %21, %5
  %12 = phi i32 [ 0, %5 ], [ %27, %21 ]
  %13 = phi i32 [ 0, %5 ], [ %26, %21 ]
    #dbg_value(i32 %12, !23, !DIExpression(), !36)
    #dbg_value(i32 %13, !22, !DIExpression(), !30)
  %14 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #3, !dbg !41
    #dbg_value(i32 %14, !25, !DIExpression(), !42)
  %15 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #3, !dbg !43
    #dbg_value(i1 %15, !28, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !42)
  br i1 %15, label %16, label %18, !dbg !44

16:                                               ; preds = %11
  %17 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 2.000000e-01) #3, !dbg !45
    #dbg_value(i32 %17, !25, !DIExpression(), !42)
  br label %18, !dbg !47

18:                                               ; preds = %16, %11
  %19 = phi i32 [ %17, %16 ], [ %14, %11 ], !dbg !42
    #dbg_value(i32 %19, !25, !DIExpression(), !42)
  br i1 %7, label %20, label %21, !dbg !48

20:                                               ; preds = %18
  tail call void @cq_phi(double noundef 3.000000e-01) #3, !dbg !49
  br label %21, !dbg !49

21:                                               ; preds = %20, %18
  %22 = tail call i32 @cq_measure_si32(i32 noundef %19) #3, !dbg !51
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %15) #3, !dbg !52
  %24 = zext i1 %23 to i32, !dbg !52
  %25 = add i32 %22, %13, !dbg !53
  %26 = add i32 %25, %24, !dbg !54
    #dbg_value(i32 %26, !22, !DIExpression(), !30)
  %27 = add nuw nsw i32 %12, 1, !dbg !55
    #dbg_value(i32 %27, !23, !DIExpression(), !36)
  %28 = icmp eq i32 %12, 0, !dbg !56
  br i1 %28, label %11, label %8, !dbg !37, !llvm.loop !57
}

declare !dbg !61 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !66 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare !dbg !69 zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare !dbg !72 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !75 zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !78 {
  %1 = tail call i32 @slice(), !dbg !79
  ret i32 %1, !dbg !80
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 !dbg !81 {
    #dbg_value(i32 %0, !84, !DIExpression(), !85)
  %2 = add nsw i32 %0, 100, !dbg !86
  ret i32 %2, !dbg !87
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.dbg.cu = !{!0, !4}
!llvm.ident = !{!6, !6}
!llvm.module.flags = !{!7, !8, !9, !10, !11, !12, !13}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !2, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!1 = !DIFile(filename: "w2i2_h1_round2.c", directory: "/Users/sorenwilkening/Desktop/CQ_wx8g/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/fix_r2_probes", checksumkind: CSK_MD5, checksum: "a4469fb0792544d4d07555a7f05b314a")
!2 = !{!3}
!3 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!4 = distinct !DICompileUnit(language: DW_LANG_C11, file: !5, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!5 = !DIFile(filename: "w2i2_lib.c", directory: "/Users/sorenwilkening/Desktop/CQ_wx8g/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/fix_r2_probes", checksumkind: CSK_MD5, checksum: "ef205ba37df11bbd7a40528f9ff9887c")
!6 = !{!"Homebrew clang version 19.1.7"}
!7 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!8 = !{i32 7, !"Dwarf Version", i32 5}
!9 = !{i32 2, !"Debug Info Version", i32 3}
!10 = !{i32 1, !"wchar_size", i32 4}
!11 = !{i32 8, !"PIC Level", i32 2}
!12 = !{i32 7, !"uwtable", i32 2}
!13 = !{i32 7, !"frame-pointer", i32 2}
!14 = distinct !DISubprogram(name: "slice", scope: !15, file: !15, line: 9, type: !16, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !19)
!15 = !DIFile(filename: "./w2i2_h1_round2.c", directory: "/Users/sorenwilkening/Desktop/CQ_wx8g/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/fix_r2_probes", checksumkind: CSK_MD5, checksum: "a4469fb0792544d4d07555a7f05b314a")
!16 = !DISubroutineType(types: !17)
!17 = !{!18}
!18 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!19 = !{!20, !21, !22, !23, !25, !28}
!20 = !DILocalVariable(name: "q", scope: !14, file: !15, line: 10, type: !18)
!21 = !DILocalVariable(name: "y", scope: !14, file: !15, line: 11, type: !18)
!22 = !DILocalVariable(name: "s", scope: !14, file: !15, line: 13, type: !18)
!23 = !DILocalVariable(name: "k", scope: !24, file: !15, line: 14, type: !18)
!24 = distinct !DILexicalBlock(scope: !14, file: !15, line: 14, column: 5)
!25 = !DILocalVariable(name: "r", scope: !26, file: !15, line: 15, type: !18)
!26 = distinct !DILexicalBlock(scope: !27, file: !15, line: 14, column: 33)
!27 = distinct !DILexicalBlock(scope: !24, file: !15, line: 14, column: 5)
!28 = !DILocalVariable(name: "t", scope: !26, file: !15, line: 16, type: !3)
!29 = !DILocation(line: 10, column: 13, scope: !14)
!30 = !DILocation(line: 0, scope: !14)
!31 = !DILocation(line: 12, column: 11, scope: !32)
!32 = distinct !DILexicalBlock(scope: !14, file: !15, line: 12, column: 9)
!33 = !DILocation(line: 12, column: 9, scope: !14)
!34 = !DILocation(line: 12, column: 20, scope: !32)
!35 = !DILocation(line: 12, column: 16, scope: !32)
!36 = !DILocation(line: 0, scope: !24)
!37 = !DILocation(line: 14, column: 5, scope: !24)
!38 = !DILocation(line: 21, column: 16, scope: !14)
!39 = !DILocation(line: 21, column: 14, scope: !14)
!40 = !DILocation(line: 21, column: 5, scope: !14)
!41 = !DILocation(line: 15, column: 18, scope: !26)
!42 = !DILocation(line: 0, scope: !26)
!43 = !DILocation(line: 16, column: 18, scope: !26)
!44 = !DILocation(line: 17, column: 13, scope: !26)
!45 = !DILocation(line: 17, column: 20, scope: !46)
!46 = distinct !DILexicalBlock(scope: !26, file: !15, line: 17, column: 13)
!47 = !DILocation(line: 17, column: 16, scope: !46)
!48 = !DILocation(line: 18, column: 13, scope: !26)
!49 = !DILocation(line: 18, column: 21, scope: !50)
!50 = distinct !DILexicalBlock(scope: !26, file: !15, line: 18, column: 13)
!51 = !DILocation(line: 19, column: 14, scope: !26)
!52 = !DILocation(line: 19, column: 30, scope: !26)
!53 = !DILocation(line: 19, column: 28, scope: !26)
!54 = !DILocation(line: 19, column: 11, scope: !26)
!55 = !DILocation(line: 14, column: 28, scope: !27)
!56 = !DILocation(line: 14, column: 23, scope: !27)
!57 = distinct !{!57, !37, !58, !59, !60}
!58 = !DILocation(line: 20, column: 5, scope: !24)
!59 = !{!"llvm.loop.mustprogress"}
!60 = !{!"llvm.loop.unroll.disable"}
!61 = !DISubprogram(name: "cq_theta_si32", scope: !62, file: !62, line: 38, type: !63, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!62 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_wx8g", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!63 = !DISubroutineType(types: !64)
!64 = !{!18, !18, !65}
!65 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!66 = !DISubprogram(name: "cq_measure_si32", scope: !62, file: !62, line: 83, type: !67, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!67 = !DISubroutineType(types: !68)
!68 = !{!18, !18}
!69 = !DISubprogram(name: "cq_theta_i1", scope: !62, file: !62, line: 32, type: !70, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!70 = !DISubroutineType(types: !71)
!71 = !{!3, !3, !65}
!72 = !DISubprogram(name: "cq_phi", scope: !62, file: !62, line: 73, type: !73, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!73 = !DISubroutineType(types: !74)
!74 = !{null, !65}
!75 = !DISubprogram(name: "cq_measure_i1", scope: !62, file: !62, line: 77, type: !76, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!76 = !DISubroutineType(types: !77)
!77 = !{!3, !3}
!78 = distinct !DISubprogram(name: "main", scope: !15, file: !15, line: 23, type: !16, scopeLine: 23, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!79 = !DILocation(line: 23, column: 25, scope: !78)
!80 = !DILocation(line: 23, column: 18, scope: !78)
!81 = distinct !DISubprogram(name: "ext_f", scope: !82, file: !82, line: 2, type: !67, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !4, retainedNodes: !83)
!82 = !DIFile(filename: "./w2i2_lib.c", directory: "/Users/sorenwilkening/Desktop/CQ_wx8g/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/fix_r2_probes", checksumkind: CSK_MD5, checksum: "ef205ba37df11bbd7a40528f9ff9887c")
!83 = !{!84}
!84 = !DILocalVariable(name: "a", arg: 1, scope: !81, file: !82, line: 2, type: !18)
!85 = !DILocation(line: 0, scope: !81)
!86 = !DILocation(line: 2, column: 29, scope: !81)
!87 = !DILocation(line: 2, column: 20, scope: !81)
