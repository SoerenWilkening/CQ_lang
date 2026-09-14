; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3, !dbg !27
    #dbg_value(i32 %1, !18, !DIExpression(), !28)
    #dbg_value(i32 5, !19, !DIExpression(), !28)
  %2 = icmp sgt i32 %1, 5, !dbg !29
  br i1 %2, label %3, label %5, !dbg !31

3:                                                ; preds = %0
  %4 = tail call i32 @ext_f(i32 noundef 7) #3, !dbg !32
    #dbg_value(i32 %4, !19, !DIExpression(), !28)
  br label %5, !dbg !33

5:                                                ; preds = %3, %0
  %6 = phi i32 [ %4, %3 ], [ 5, %0 ], !dbg !28
    #dbg_value(i32 %6, !19, !DIExpression(), !28)
    #dbg_value(i32 0, !20, !DIExpression(), !28)
    #dbg_value(i32 0, !21, !DIExpression(), !34)
  %7 = icmp sgt i32 %6, 50
  br label %11, !dbg !35

8:                                                ; preds = %22
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #3, !dbg !36
  %10 = add nsw i32 %9, %26, !dbg !37
  ret i32 %10, !dbg !38

11:                                               ; preds = %22, %5
  %12 = phi i32 [ 0, %5 ], [ %27, %22 ]
  %13 = phi i32 [ 0, %5 ], [ %26, %22 ]
    #dbg_value(i32 %12, !21, !DIExpression(), !34)
    #dbg_value(i32 %13, !20, !DIExpression(), !28)
  %14 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #3, !dbg !39
    #dbg_value(i32 %14, !23, !DIExpression(), !40)
  %15 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 4.000000e-01) #3, !dbg !41
    #dbg_value(i32 %15, !26, !DIExpression(), !40)
  %16 = icmp eq i32 %15, 1, !dbg !42
  br i1 %16, label %17, label %19, !dbg !44

17:                                               ; preds = %11
  %18 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 2.000000e-01) #3, !dbg !45
    #dbg_value(i32 %18, !23, !DIExpression(), !40)
  br label %19, !dbg !46

19:                                               ; preds = %17, %11
  %20 = phi i32 [ %18, %17 ], [ %14, %11 ], !dbg !40
    #dbg_value(i32 %20, !23, !DIExpression(), !40)
  br i1 %7, label %21, label %22, !dbg !47

21:                                               ; preds = %19
  tail call void @cq_phi(double noundef 3.000000e-01) #3, !dbg !48
  br label %22, !dbg !48

22:                                               ; preds = %21, %19
  %23 = tail call i32 @cq_measure_si32(i32 noundef %20) #3, !dbg !50
  %24 = tail call i32 @cq_measure_si32(i32 noundef %15) #3, !dbg !51
  %25 = add i32 %23, %13, !dbg !52
  %26 = add i32 %25, %24, !dbg !53
    #dbg_value(i32 %26, !20, !DIExpression(), !28)
  %27 = add nuw nsw i32 %12, 1, !dbg !54
    #dbg_value(i32 %27, !21, !DIExpression(), !34)
  %28 = icmp eq i32 %12, 0, !dbg !55
  br i1 %28, label %11, label %8, !dbg !35, !llvm.loop !56
}

declare !dbg !60 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !65 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare !dbg !68 void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !71 {
  %1 = tail call i32 @slice(), !dbg !72
  ret i32 %1, !dbg !73
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 !dbg !74 {
    #dbg_value(i32 %0, !77, !DIExpression(), !78)
  %2 = add nsw i32 %0, 100, !dbg !79
  ret i32 %2, !dbg !80
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.dbg.cu = !{!0, !2}
!llvm.ident = !{!4, !4}
!llvm.module.flags = !{!5, !6, !7, !8, !9, !10, !11}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!1 = !DIFile(filename: "w2i3_h1_cmpcond.c", directory: "/Users/sorenwilkening/Desktop/CQ_wx8g/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/fix_r2_probes", checksumkind: CSK_MD5, checksum: "e1d25f8ca15f608ae51650cfa0f9feef")
!2 = distinct !DICompileUnit(language: DW_LANG_C11, file: !3, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!3 = !DIFile(filename: "w2i2_lib.c", directory: "/Users/sorenwilkening/Desktop/CQ_wx8g/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/fix_r2_probes", checksumkind: CSK_MD5, checksum: "ef205ba37df11bbd7a40528f9ff9887c")
!4 = !{!"Homebrew clang version 19.1.7"}
!5 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!6 = !{i32 7, !"Dwarf Version", i32 5}
!7 = !{i32 2, !"Debug Info Version", i32 3}
!8 = !{i32 1, !"wchar_size", i32 4}
!9 = !{i32 8, !"PIC Level", i32 2}
!10 = !{i32 7, !"uwtable", i32 2}
!11 = !{i32 7, !"frame-pointer", i32 2}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 9, type: !14, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0, retainedNodes: !17)
!13 = !DIFile(filename: "./w2i3_h1_cmpcond.c", directory: "/Users/sorenwilkening/Desktop/CQ_wx8g/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/fix_r2_probes", checksumkind: CSK_MD5, checksum: "e1d25f8ca15f608ae51650cfa0f9feef")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !20, !21, !23, !26}
!18 = !DILocalVariable(name: "q", scope: !12, file: !13, line: 10, type: !16)
!19 = !DILocalVariable(name: "y", scope: !12, file: !13, line: 11, type: !16)
!20 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 13, type: !16)
!21 = !DILocalVariable(name: "k", scope: !22, file: !13, line: 14, type: !16)
!22 = distinct !DILexicalBlock(scope: !12, file: !13, line: 14, column: 5)
!23 = !DILocalVariable(name: "r", scope: !24, file: !13, line: 15, type: !16)
!24 = distinct !DILexicalBlock(scope: !25, file: !13, line: 14, column: 33)
!25 = distinct !DILexicalBlock(scope: !22, file: !13, line: 14, column: 5)
!26 = !DILocalVariable(name: "t", scope: !24, file: !13, line: 16, type: !16)
!27 = !DILocation(line: 10, column: 13, scope: !12)
!28 = !DILocation(line: 0, scope: !12)
!29 = !DILocation(line: 12, column: 11, scope: !30)
!30 = distinct !DILexicalBlock(scope: !12, file: !13, line: 12, column: 9)
!31 = !DILocation(line: 12, column: 9, scope: !12)
!32 = !DILocation(line: 12, column: 20, scope: !30)
!33 = !DILocation(line: 12, column: 16, scope: !30)
!34 = !DILocation(line: 0, scope: !22)
!35 = !DILocation(line: 14, column: 5, scope: !22)
!36 = !DILocation(line: 21, column: 16, scope: !12)
!37 = !DILocation(line: 21, column: 14, scope: !12)
!38 = !DILocation(line: 21, column: 5, scope: !12)
!39 = !DILocation(line: 15, column: 18, scope: !24)
!40 = !DILocation(line: 0, scope: !24)
!41 = !DILocation(line: 16, column: 17, scope: !24)
!42 = !DILocation(line: 17, column: 15, scope: !43)
!43 = distinct !DILexicalBlock(scope: !24, file: !13, line: 17, column: 13)
!44 = !DILocation(line: 17, column: 13, scope: !24)
!45 = !DILocation(line: 17, column: 25, scope: !43)
!46 = !DILocation(line: 17, column: 21, scope: !43)
!47 = !DILocation(line: 18, column: 13, scope: !24)
!48 = !DILocation(line: 18, column: 21, scope: !49)
!49 = distinct !DILexicalBlock(scope: !24, file: !13, line: 18, column: 13)
!50 = !DILocation(line: 19, column: 14, scope: !24)
!51 = !DILocation(line: 19, column: 30, scope: !24)
!52 = !DILocation(line: 19, column: 28, scope: !24)
!53 = !DILocation(line: 19, column: 11, scope: !24)
!54 = !DILocation(line: 14, column: 28, scope: !25)
!55 = !DILocation(line: 14, column: 23, scope: !25)
!56 = distinct !{!56, !35, !57, !58, !59}
!57 = !DILocation(line: 20, column: 5, scope: !22)
!58 = !{!"llvm.loop.mustprogress"}
!59 = !{!"llvm.loop.unroll.disable"}
!60 = !DISubprogram(name: "cq_theta_si32", scope: !61, file: !61, line: 38, type: !62, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!61 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_wx8g", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!62 = !DISubroutineType(types: !63)
!63 = !{!16, !16, !64}
!64 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!65 = !DISubprogram(name: "cq_measure_si32", scope: !61, file: !61, line: 83, type: !66, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!66 = !DISubroutineType(types: !67)
!67 = !{!16, !16}
!68 = !DISubprogram(name: "cq_phi", scope: !61, file: !61, line: 73, type: !69, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!69 = !DISubroutineType(types: !70)
!70 = !{null, !64}
!71 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 23, type: !14, scopeLine: 23, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !0)
!72 = !DILocation(line: 23, column: 25, scope: !71)
!73 = !DILocation(line: 23, column: 18, scope: !71)
!74 = distinct !DISubprogram(name: "ext_f", scope: !75, file: !75, line: 2, type: !66, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2, retainedNodes: !76)
!75 = !DIFile(filename: "./w2i2_lib.c", directory: "/Users/sorenwilkening/Desktop/CQ_wx8g/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/fix_r2_probes", checksumkind: CSK_MD5, checksum: "ef205ba37df11bbd7a40528f9ff9887c")
!76 = !{!77}
!77 = !DILocalVariable(name: "a", arg: 1, scope: !74, file: !75, line: 2, type: !16)
!78 = !DILocation(line: 0, scope: !74)
!79 = !DILocation(line: 2, column: 29, scope: !74)
!80 = !DILocation(line: 2, column: 20, scope: !74)
