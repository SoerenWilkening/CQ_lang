; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2h_phase_inloop_invread_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2h_phase_inloop_invread_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !21
    #dbg_value(i32 %1, !15, !DIExpression(), !22)
    #dbg_value(i32 0, !16, !DIExpression(), !22)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !23
    #dbg_value(i32 %2, !17, !DIExpression(), !24)
  %3 = and i32 %2, 2, !dbg !25
  %4 = icmp eq i32 %3, 0, !dbg !25
  br i1 %4, label %6, label %5, !dbg !27

5:                                                ; preds = %0
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !28
  br label %6, !dbg !28

6:                                                ; preds = %5, %0
  %7 = lshr i32 %2, 2, !dbg !29
  %8 = and i32 %7, 1, !dbg !29
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !29
  %10 = and i32 %1, 1, !dbg !30
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !30
    #dbg_value(!DIArgList(i32 %9, i32 %11), !16, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !22)
  %12 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !31
    #dbg_value(i32 %12, !19, !DIExpression(), !32)
  %13 = and i32 %12, 2, !dbg !33
  %14 = icmp eq i32 %13, 0, !dbg !33
  br i1 %14, label %16, label %15, !dbg !35

15:                                               ; preds = %6
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !36
  br label %16, !dbg !36

16:                                               ; preds = %15, %6
    #dbg_value(i32 poison, !16, !DIExpression(), !22)
  %17 = lshr i32 %12, 2, !dbg !37
  %18 = and i32 %17, 1, !dbg !37
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #2, !dbg !37
  %20 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !38
    #dbg_value(i32 %24, !16, !DIExpression(), !22)
  %21 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !39
  %22 = add i32 %11, %9, !dbg !40
  %23 = add i32 %22, %19, !dbg !41
  %24 = add i32 %23, %20, !dbg !42
  %25 = add nsw i32 %24, %21, !dbg !43
  ret i32 %25, !dbg !44
}

declare !dbg !45 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !50 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !53 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !56 {
  %1 = tail call i32 @slice(), !dbg !57
  ret i32 %1, !dbg !58
}

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/src/w2h_phase_inloop_invread_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "b6937792b609ac9d7b2222148b7814c3")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!17 = !DILocalVariable(name: "u", scope: !18, file: !8, line: 6, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 5)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 8, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!21 = !DILocation(line: 4, column: 14, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 6, column: 15, scope: !18)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 6, column: 46, scope: !26)
!26 = distinct !DILexicalBlock(scope: !18, file: !8, line: 6, column: 37)
!27 = !DILocation(line: 6, column: 37, scope: !18)
!28 = !DILocation(line: 6, column: 51, scope: !26)
!29 = !DILocation(line: 7, column: 12, scope: !18)
!30 = !DILocation(line: 7, column: 39, scope: !18)
!31 = !DILocation(line: 8, column: 15, scope: !20)
!32 = !DILocation(line: 0, scope: !20)
!33 = !DILocation(line: 8, column: 46, scope: !34)
!34 = distinct !DILexicalBlock(scope: !20, file: !8, line: 8, column: 37)
!35 = !DILocation(line: 8, column: 37, scope: !20)
!36 = !DILocation(line: 8, column: 51, scope: !34)
!37 = !DILocation(line: 9, column: 12, scope: !20)
!38 = !DILocation(line: 9, column: 39, scope: !20)
!39 = !DILocation(line: 10, column: 16, scope: !10)
!40 = !DILocation(line: 9, column: 37, scope: !20)
!41 = !DILocation(line: 7, column: 37, scope: !18)
!42 = !DILocation(line: 9, column: 9, scope: !20)
!43 = !DILocation(line: 10, column: 14, scope: !10)
!44 = !DILocation(line: 10, column: 5, scope: !10)
!45 = !DISubprogram(name: "cq_theta_si32", scope: !46, file: !46, line: 38, type: !47, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!46 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!47 = !DISubroutineType(types: !48)
!48 = !{!13, !13, !49}
!49 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!50 = !DISubprogram(name: "cq_phi", scope: !46, file: !46, line: 73, type: !51, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!51 = !DISubroutineType(types: !52)
!52 = !{null, !49}
!53 = !DISubprogram(name: "cq_measure_si32", scope: !46, file: !46, line: 83, type: !54, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!54 = !DISubroutineType(types: !55)
!55 = !{!13, !13}
!56 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 12, type: !11, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!57 = !DILocation(line: 12, column: 25, scope: !56)
!58 = !DILocation(line: 12, column: 18, scope: !56)
