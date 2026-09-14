; ModuleID = 'b7c_w2h_interfered_un.c'
source_filename = "b7c_w2h_interfered_un.c"
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
  %12 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2, !dbg !31
    #dbg_value(i32 %12, !17, !DIExpression(), !24)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !32
    #dbg_value(!DIArgList(i32 %9, i32 %13, i32 %11), !16, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 2, DW_OP_plus, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !22)
  %14 = tail call i32 @cq_theta_si32(i32 noundef 6, double noundef 4.000000e-01) #2, !dbg !33
    #dbg_value(i32 %14, !19, !DIExpression(), !34)
  %15 = and i32 %14, 2, !dbg !35
  %16 = icmp eq i32 %15, 0, !dbg !35
  br i1 %16, label %18, label %17, !dbg !37

17:                                               ; preds = %6
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !38
  br label %18, !dbg !38

18:                                               ; preds = %17, %6
    #dbg_value(!DIArgList(i32 poison, i32 poison), !16, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !22)
    #dbg_value(i32 poison, !16, !DIExpression(), !22)
  %19 = lshr i32 %14, 2, !dbg !39
  %20 = and i32 %19, 1, !dbg !39
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #2, !dbg !39
  %22 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !40
    #dbg_value(i32 %29, !16, !DIExpression(), !22)
  %23 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 9.000000e-01) #2, !dbg !41
    #dbg_value(i32 %23, !19, !DIExpression(), !34)
  %24 = tail call i32 @cq_measure_si32(i32 noundef %23) #2, !dbg !42
    #dbg_value(i32 %30, !16, !DIExpression(), !22)
  %25 = tail call i32 @cq_measure_si32(i32 noundef %1) #2, !dbg !43
  %26 = add i32 %11, %9, !dbg !44
  %27 = add i32 %26, %13, !dbg !45
  %28 = add i32 %27, %21, !dbg !46
  %29 = add i32 %28, %22, !dbg !47
  %30 = add nsw i32 %29, %24, !dbg !48
  %31 = add nsw i32 %30, %25, !dbg !49
  ret i32 %31, !dbg !50
}

declare !dbg !51 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !56 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !59 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !62 {
  %1 = tail call i32 @slice(), !dbg !63
  ret i32 %1, !dbg !64
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
!8 = !DIFile(filename: "b7c_w2h_interfered_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "fc91121c1779053b98a380c9ac190cd0")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !19}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "u", scope: !18, file: !8, line: 5, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 5, column: 5)
!19 = !DILocalVariable(name: "u", scope: !20, file: !8, line: 10, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 5)
!21 = !DILocation(line: 3, column: 14, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 5, column: 17, scope: !18)
!24 = !DILocation(line: 0, scope: !18)
!25 = !DILocation(line: 6, column: 22, scope: !26)
!26 = distinct !DILexicalBlock(scope: !18, file: !8, line: 6, column: 13)
!27 = !DILocation(line: 6, column: 13, scope: !18)
!28 = !DILocation(line: 6, column: 27, scope: !26)
!29 = !DILocation(line: 7, column: 14, scope: !18)
!30 = !DILocation(line: 7, column: 41, scope: !18)
!31 = !DILocation(line: 8, column: 13, scope: !18)
!32 = !DILocation(line: 9, column: 14, scope: !18)
!33 = !DILocation(line: 10, column: 17, scope: !20)
!34 = !DILocation(line: 0, scope: !20)
!35 = !DILocation(line: 11, column: 22, scope: !36)
!36 = distinct !DILexicalBlock(scope: !20, file: !8, line: 11, column: 13)
!37 = !DILocation(line: 11, column: 13, scope: !20)
!38 = !DILocation(line: 11, column: 27, scope: !36)
!39 = !DILocation(line: 12, column: 14, scope: !20)
!40 = !DILocation(line: 12, column: 41, scope: !20)
!41 = !DILocation(line: 13, column: 13, scope: !20)
!42 = !DILocation(line: 14, column: 14, scope: !20)
!43 = !DILocation(line: 15, column: 16, scope: !10)
!44 = !DILocation(line: 12, column: 39, scope: !20)
!45 = !DILocation(line: 7, column: 39, scope: !18)
!46 = !DILocation(line: 9, column: 11, scope: !18)
!47 = !DILocation(line: 12, column: 11, scope: !20)
!48 = !DILocation(line: 14, column: 11, scope: !20)
!49 = !DILocation(line: 15, column: 14, scope: !10)
!50 = !DILocation(line: 15, column: 5, scope: !10)
!51 = !DISubprogram(name: "cq_theta_si32", scope: !52, file: !52, line: 38, type: !53, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!52 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_S", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!53 = !DISubroutineType(types: !54)
!54 = !{!13, !13, !55}
!55 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!56 = !DISubprogram(name: "cq_phi", scope: !52, file: !52, line: 73, type: !57, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!57 = !DISubroutineType(types: !58)
!58 = !{null, !55}
!59 = !DISubprogram(name: "cq_measure_si32", scope: !52, file: !52, line: 83, type: !60, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!60 = !DISubroutineType(types: !61)
!61 = !{!13, !13}
!62 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 17, type: !11, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!63 = !DILocation(line: 17, column: 25, scope: !62)
!64 = !DILocation(line: 17, column: 18, scope: !62)
