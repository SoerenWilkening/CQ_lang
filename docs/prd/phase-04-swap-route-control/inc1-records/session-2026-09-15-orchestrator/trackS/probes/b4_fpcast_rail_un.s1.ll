; ModuleID = 'b4_fpcast_rail_un.c'
source_filename = "b4_fpcast_rail_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @slice() local_unnamed_addr #0 !dbg !14 {
  %1 = tail call double @cq_theta_f64(double noundef 5.000000e+00, double noundef 5.000000e-01) #2, !dbg !21
    #dbg_value(double %1, !18, !DIExpression(), !22)
    #dbg_value(double %1, !19, !DIExpression(), !22)
    #dbg_value(double 0.000000e+00, !20, !DIExpression(), !22)
  %2 = fptrunc double %1 to float, !dbg !23
  %3 = fpext float %2 to double, !dbg !24
    #dbg_value(double %3, !19, !DIExpression(), !22)
  %4 = tail call double @cq_measure_f64(double noundef %3) #2, !dbg !25
  %5 = fadd double %4, 0.000000e+00, !dbg !26
    #dbg_value(double %5, !20, !DIExpression(), !22)
    #dbg_value(double %3, !19, !DIExpression(), !22)
  %6 = tail call double @cq_measure_f64(double noundef %3) #2, !dbg !27
  %7 = fadd double %5, %6, !dbg !28
    #dbg_value(double %7, !20, !DIExpression(), !22)
  %8 = tail call double @cq_theta_f64(double noundef %1, double noundef 9.000000e-01) #2, !dbg !29
    #dbg_value(double %8, !18, !DIExpression(), !22)
  %9 = tail call double @cq_measure_f64(double noundef %8) #2, !dbg !30
  %10 = fadd double %7, %9, !dbg !31
  ret double %10, !dbg !32
}

declare !dbg !33 double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

declare !dbg !37 double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !40 {
  %1 = tail call double @cq_theta_f64(double noundef 5.000000e+00, double noundef 5.000000e-01) #2, !dbg !43
    #dbg_value(double %1, !18, !DIExpression(), !45)
    #dbg_value(double %1, !19, !DIExpression(), !45)
    #dbg_value(double 0.000000e+00, !20, !DIExpression(), !45)
  %2 = fptrunc double %1 to float, !dbg !46
  %3 = fpext float %2 to double, !dbg !47
    #dbg_value(double %3, !19, !DIExpression(), !45)
  %4 = tail call double @cq_measure_f64(double noundef %3) #2, !dbg !48
  %5 = fadd double %4, 0.000000e+00, !dbg !49
    #dbg_value(double %5, !20, !DIExpression(), !45)
    #dbg_value(double %3, !19, !DIExpression(), !45)
  %6 = tail call double @cq_measure_f64(double noundef %3) #2, !dbg !50
  %7 = fadd double %5, %6, !dbg !51
    #dbg_value(double %7, !20, !DIExpression(), !45)
  %8 = tail call double @cq_theta_f64(double noundef %1, double noundef 9.000000e-01) #2, !dbg !52
    #dbg_value(double %8, !18, !DIExpression(), !45)
  %9 = tail call double @cq_measure_f64(double noundef %8) #2, !dbg !53
  %10 = fadd double %7, %9, !dbg !54
  %11 = fptosi double %10 to i32, !dbg !55
  ret i32 %11, !dbg !56
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
!8 = !DIFile(filename: "b4_fpcast_rail_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "42c7536b8b529376a550fde29776119f")
!9 = !{!10, !11, !12}
!10 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!11 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!12 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!13 = !{!"Homebrew clang version 19.1.7"}
!14 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !15, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!15 = !DISubroutineType(types: !16)
!16 = !{!10}
!17 = !{!18, !19, !20}
!18 = !DILocalVariable(name: "y", scope: !14, file: !8, line: 3, type: !10)
!19 = !DILocalVariable(name: "w", scope: !14, file: !8, line: 4, type: !10)
!20 = !DILocalVariable(name: "s", scope: !14, file: !8, line: 5, type: !10)
!21 = !DILocation(line: 3, column: 16, scope: !14)
!22 = !DILocation(line: 0, scope: !14)
!23 = !DILocation(line: 6, column: 17, scope: !14)
!24 = !DILocation(line: 6, column: 9, scope: !14)
!25 = !DILocation(line: 6, column: 32, scope: !14)
!26 = !DILocation(line: 6, column: 29, scope: !14)
!27 = !DILocation(line: 7, column: 32, scope: !14)
!28 = !DILocation(line: 7, column: 29, scope: !14)
!29 = !DILocation(line: 8, column: 9, scope: !14)
!30 = !DILocation(line: 9, column: 16, scope: !14)
!31 = !DILocation(line: 9, column: 14, scope: !14)
!32 = !DILocation(line: 9, column: 5, scope: !14)
!33 = !DISubprogram(name: "cq_theta_f64", scope: !34, file: !34, line: 45, type: !35, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!34 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_S", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!35 = !DISubroutineType(types: !36)
!36 = !{!10, !10, !10}
!37 = !DISubprogram(name: "cq_measure_f64", scope: !34, file: !34, line: 90, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = !DISubroutineType(types: !39)
!39 = !{!10, !10}
!40 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !41, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!41 = !DISubroutineType(types: !42)
!42 = !{!12}
!43 = !DILocation(line: 3, column: 16, scope: !14, inlinedAt: !44)
!44 = distinct !DILocation(line: 11, column: 30, scope: !40)
!45 = !DILocation(line: 0, scope: !14, inlinedAt: !44)
!46 = !DILocation(line: 6, column: 17, scope: !14, inlinedAt: !44)
!47 = !DILocation(line: 6, column: 9, scope: !14, inlinedAt: !44)
!48 = !DILocation(line: 6, column: 32, scope: !14, inlinedAt: !44)
!49 = !DILocation(line: 6, column: 29, scope: !14, inlinedAt: !44)
!50 = !DILocation(line: 7, column: 32, scope: !14, inlinedAt: !44)
!51 = !DILocation(line: 7, column: 29, scope: !14, inlinedAt: !44)
!52 = !DILocation(line: 8, column: 9, scope: !14, inlinedAt: !44)
!53 = !DILocation(line: 9, column: 16, scope: !14, inlinedAt: !44)
!54 = !DILocation(line: 9, column: 14, scope: !14, inlinedAt: !44)
!55 = !DILocation(line: 11, column: 25, scope: !40)
!56 = !DILocation(line: 11, column: 18, scope: !40)
