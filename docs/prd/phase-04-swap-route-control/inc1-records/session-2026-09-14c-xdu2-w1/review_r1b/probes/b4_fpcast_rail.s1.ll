; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b4_fpcast_rail.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b4_fpcast_rail.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @slice() local_unnamed_addr #0 !dbg !14 {
  %1 = tail call double @cq_theta_f64(double noundef 5.000000e+00, double noundef 5.000000e-01) #2, !dbg !23
    #dbg_value(double %1, !18, !DIExpression(), !24)
    #dbg_value(double %1, !19, !DIExpression(), !24)
    #dbg_value(double 0.000000e+00, !20, !DIExpression(), !24)
    #dbg_value(i32 0, !21, !DIExpression(), !25)
  %2 = fptrunc double %1 to float, !dbg !26
  %3 = fpext float %2 to double
    #dbg_value(i32 0, !21, !DIExpression(), !25)
    #dbg_value(double 0.000000e+00, !20, !DIExpression(), !24)
    #dbg_value(double poison, !19, !DIExpression(), !24)
  br label %8, !dbg !29

4:                                                ; preds = %8
  %5 = tail call double @cq_theta_f64(double noundef %1, double noundef 9.000000e-01) #2, !dbg !30
    #dbg_value(double %5, !18, !DIExpression(), !24)
  %6 = tail call double @cq_measure_f64(double noundef %5) #2, !dbg !31
  %7 = fadd double %12, %6, !dbg !32
  ret double %7, !dbg !33

8:                                                ; preds = %0, %8
  %9 = phi i32 [ 0, %0 ], [ %13, %8 ]
  %10 = phi double [ 0.000000e+00, %0 ], [ %12, %8 ]
    #dbg_value(i32 %9, !21, !DIExpression(), !25)
    #dbg_value(double %10, !20, !DIExpression(), !24)
    #dbg_value(double %3, !19, !DIExpression(), !24)
  %11 = tail call double @cq_measure_f64(double noundef %3) #2, !dbg !34
  %12 = fadd double %10, %11, !dbg !35
    #dbg_value(double %12, !20, !DIExpression(), !24)
  %13 = add nuw nsw i32 %9, 1, !dbg !36
    #dbg_value(i32 %13, !21, !DIExpression(), !25)
    #dbg_value(double poison, !19, !DIExpression(), !24)
  %14 = icmp eq i32 %9, 0, !dbg !37
  br i1 %14, label %8, label %4, !dbg !29, !llvm.loop !38
}

declare !dbg !42 double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare !dbg !46 double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !49 {
  %1 = tail call double @cq_theta_f64(double noundef 5.000000e+00, double noundef 5.000000e-01) #2, !dbg !52
    #dbg_value(double %1, !18, !DIExpression(), !54)
    #dbg_value(double %1, !19, !DIExpression(), !54)
    #dbg_value(double 0.000000e+00, !20, !DIExpression(), !54)
    #dbg_value(i32 0, !21, !DIExpression(), !55)
  %2 = fptrunc double %1 to float, !dbg !56
  %3 = fpext float %2 to double
    #dbg_value(i32 0, !21, !DIExpression(), !55)
    #dbg_value(double 0.000000e+00, !20, !DIExpression(), !54)
    #dbg_value(double poison, !19, !DIExpression(), !54)
  br label %4, !dbg !57

4:                                                ; preds = %4, %0
  %5 = phi i32 [ 0, %0 ], [ %9, %4 ]
  %6 = phi double [ 0.000000e+00, %0 ], [ %8, %4 ]
    #dbg_value(i32 %5, !21, !DIExpression(), !55)
    #dbg_value(double %6, !20, !DIExpression(), !54)
    #dbg_value(double %3, !19, !DIExpression(), !54)
  %7 = tail call double @cq_measure_f64(double noundef %3) #2, !dbg !58
  %8 = fadd double %6, %7, !dbg !59
    #dbg_value(double %8, !20, !DIExpression(), !54)
  %9 = add nuw nsw i32 %5, 1, !dbg !60
    #dbg_value(i32 %9, !21, !DIExpression(), !55)
    #dbg_value(double poison, !19, !DIExpression(), !54)
  %10 = icmp eq i32 %5, 0, !dbg !61
  br i1 %10, label %4, label %11, !dbg !57, !llvm.loop !62

11:                                               ; preds = %4
  %12 = tail call double @cq_theta_f64(double noundef %1, double noundef 9.000000e-01) #2, !dbg !64
    #dbg_value(double %12, !18, !DIExpression(), !54)
  %13 = tail call double @cq_measure_f64(double noundef %12) #2, !dbg !65
  %14 = fadd double %8, %13, !dbg !66
  %15 = fptosi double %14 to i32, !dbg !67
  ret i32 %15, !dbg !68
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!13}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b4_fpcast_rail.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "80c7f6aebd5a5f66fdd1b01fb85e5995")
!9 = !{!10, !11, !12}
!10 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!11 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!12 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!13 = !{!"Homebrew clang version 19.1.7"}
!14 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !15, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!15 = !DISubroutineType(types: !16)
!16 = !{!10}
!17 = !{!18, !19, !20, !21}
!18 = !DILocalVariable(name: "y", scope: !14, file: !8, line: 7, type: !10)
!19 = !DILocalVariable(name: "w", scope: !14, file: !8, line: 8, type: !10)
!20 = !DILocalVariable(name: "s", scope: !14, file: !8, line: 9, type: !10)
!21 = !DILocalVariable(name: "k", scope: !22, file: !8, line: 10, type: !12)
!22 = distinct !DILexicalBlock(scope: !14, file: !8, line: 10, column: 5)
!23 = !DILocation(line: 7, column: 16, scope: !14)
!24 = !DILocation(line: 0, scope: !14)
!25 = !DILocation(line: 0, scope: !22)
!26 = !DILocation(line: 11, column: 21, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !8, line: 10, column: 33)
!28 = distinct !DILexicalBlock(scope: !22, file: !8, line: 10, column: 5)
!29 = !DILocation(line: 10, column: 5, scope: !22)
!30 = !DILocation(line: 14, column: 9, scope: !14)
!31 = !DILocation(line: 15, column: 16, scope: !14)
!32 = !DILocation(line: 15, column: 14, scope: !14)
!33 = !DILocation(line: 15, column: 5, scope: !14)
!34 = !DILocation(line: 12, column: 14, scope: !27)
!35 = !DILocation(line: 12, column: 11, scope: !27)
!36 = !DILocation(line: 10, column: 28, scope: !28)
!37 = !DILocation(line: 10, column: 23, scope: !28)
!38 = distinct !{!38, !29, !39, !40, !41}
!39 = !DILocation(line: 13, column: 5, scope: !22)
!40 = !{!"llvm.loop.mustprogress"}
!41 = !{!"llvm.loop.unroll.disable"}
!42 = !DISubprogram(name: "cq_theta_f64", scope: !43, file: !43, line: 45, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!44 = !DISubroutineType(types: !45)
!45 = !{!10, !10, !10}
!46 = !DISubprogram(name: "cq_measure_f64", scope: !43, file: !43, line: 90, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!47 = !DISubroutineType(types: !48)
!48 = !{!10, !10}
!49 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 17, type: !50, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!50 = !DISubroutineType(types: !51)
!51 = !{!12}
!52 = !DILocation(line: 7, column: 16, scope: !14, inlinedAt: !53)
!53 = distinct !DILocation(line: 17, column: 30, scope: !49)
!54 = !DILocation(line: 0, scope: !14, inlinedAt: !53)
!55 = !DILocation(line: 0, scope: !22, inlinedAt: !53)
!56 = !DILocation(line: 11, column: 21, scope: !27, inlinedAt: !53)
!57 = !DILocation(line: 10, column: 5, scope: !22, inlinedAt: !53)
!58 = !DILocation(line: 12, column: 14, scope: !27, inlinedAt: !53)
!59 = !DILocation(line: 12, column: 11, scope: !27, inlinedAt: !53)
!60 = !DILocation(line: 10, column: 28, scope: !28, inlinedAt: !53)
!61 = !DILocation(line: 10, column: 23, scope: !28, inlinedAt: !53)
!62 = distinct !{!62, !57, !63, !40, !41}
!63 = !DILocation(line: 13, column: 5, scope: !22, inlinedAt: !53)
!64 = !DILocation(line: 14, column: 9, scope: !14, inlinedAt: !53)
!65 = !DILocation(line: 15, column: 16, scope: !14, inlinedAt: !53)
!66 = !DILocation(line: 15, column: 14, scope: !14, inlinedAt: !53)
!67 = !DILocation(line: 17, column: 25, scope: !49)
!68 = !DILocation(line: 17, column: 18, scope: !49)
