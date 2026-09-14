; ModuleID = 'src/od7_grover_rolled_customer.c'
source_filename = "src/od7_grover_rolled_customer.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2, !dbg !19
    #dbg_value(i32 %1, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 0, !17, !DIExpression(), !21)
  br label %4, !dbg !22

2:                                                ; preds = %10
  %3 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !23
    #dbg_value(i32 %3, !16, !DIExpression(), !20)
  ret i32 %3, !dbg !24

4:                                                ; preds = %0, %10
  %5 = phi i32 [ 0, %0 ], [ %11, %10 ]
  %6 = phi i32 [ %1, %0 ], [ %7, %10 ]
    #dbg_value(i32 %5, !17, !DIExpression(), !21)
    #dbg_value(i32 %6, !15, !DIExpression(), !20)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.000000e-01) #2, !dbg !25
    #dbg_value(i32 %7, !15, !DIExpression(), !20)
  %8 = icmp eq i32 %7, 5, !dbg !28
  br i1 %8, label %9, label %10, !dbg !30

9:                                                ; preds = %4
  tail call void @cq_phi(double noundef 3.141590e+00) #2, !dbg !31
  br label %10, !dbg !31

10:                                               ; preds = %4, %9
  %11 = add nuw nsw i32 %5, 1, !dbg !32
    #dbg_value(i32 %11, !17, !DIExpression(), !21)
    #dbg_value(i32 %7, !15, !DIExpression(), !20)
  %12 = icmp eq i32 %11, 3, !dbg !33
  br i1 %12, label %2, label %4, !dbg !22, !llvm.loop !34
}

declare !dbg !38 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !43 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !46 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
!8 = !DIFile(filename: "src/od7_grover_rolled_customer.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackD/review_r2_probes", checksumkind: CSK_MD5, checksum: "d931f8d56af8dd4722b740992ab3e848")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "q", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 3, type: !13)
!17 = !DILocalVariable(name: "i", scope: !18, file: !8, line: 4, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 4, column: 3)
!19 = !DILocation(line: 3, column: 23, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 4, column: 3, scope: !18)
!23 = !DILocation(line: 5, column: 6, scope: !10)
!24 = !DILocation(line: 5, column: 21, scope: !10)
!25 = !DILocation(line: 4, column: 27, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !8, line: 4, column: 23)
!27 = distinct !DILexicalBlock(scope: !18, file: !8, line: 4, column: 3)
!28 = !DILocation(line: 4, column: 48, scope: !29)
!29 = distinct !DILexicalBlock(scope: !26, file: !8, line: 4, column: 47)
!30 = !DILocation(line: 4, column: 47, scope: !26)
!31 = !DILocation(line: 4, column: 53, scope: !29)
!32 = !DILocation(line: 4, column: 20, scope: !27)
!33 = !DILocation(line: 4, column: 16, scope: !27)
!34 = distinct !{!34, !22, !35, !36, !37}
!35 = !DILocation(line: 4, column: 70, scope: !18)
!36 = !{!"llvm.loop.mustprogress"}
!37 = !{!"llvm.loop.unroll.disable"}
!38 = !DISubprogram(name: "cq_theta_si32", scope: !39, file: !39, line: 38, type: !40, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!39 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!40 = !DISubroutineType(types: !41)
!41 = !{!13, !13, !42}
!42 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!43 = !DISubprogram(name: "cq_phi", scope: !39, file: !39, line: 73, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!44 = !DISubroutineType(types: !45)
!45 = !{null, !42}
!46 = !DISubprogram(name: "cq_measure_si32", scope: !39, file: !39, line: 83, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DISubroutineType(types: !48)
!48 = !{!13, !13}
