; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b1_condloop_dom_un.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b1_condloop_dom_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !18)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !19
    #dbg_value(i32 %2, !16, !DIExpression(), !18)
    #dbg_value(i32 0, !17, !DIExpression(), !18)
  %3 = icmp eq i32 %0, 0, !dbg !20
  br i1 %3, label %12, label %4, !dbg !22

4:                                                ; preds = %1
  %5 = lshr i32 %2, 1, !dbg !23
  %6 = and i32 %5, 1, !dbg !23
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2, !dbg !23
    #dbg_value(i32 %7, !17, !DIExpression(), !18)
  %8 = lshr i32 %2, 2, !dbg !25
  %9 = and i32 %8, 1, !dbg !25
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !25
  %11 = add nsw i32 %10, %7, !dbg !26
    #dbg_value(i32 %11, !17, !DIExpression(), !18)
  br label %12, !dbg !27

12:                                               ; preds = %4, %1
  %13 = phi i32 [ %11, %4 ], [ 0, %1 ], !dbg !18
    #dbg_value(i32 %13, !17, !DIExpression(), !18)
  %14 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2, !dbg !28
    #dbg_value(i32 %14, !16, !DIExpression(), !18)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2, !dbg !29
  %16 = add nsw i32 %15, %13, !dbg !30
  ret i32 %16, !dbg !31
}

declare !dbg !32 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !37 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !38 {
    #dbg_value(i32 %0, !45, !DIExpression(), !47)
    #dbg_value(ptr %1, !46, !DIExpression(), !47)
    #dbg_value(i32 %0, !15, !DIExpression(), !48)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !50
    #dbg_value(i32 %3, !16, !DIExpression(), !48)
    #dbg_value(i32 0, !17, !DIExpression(), !48)
  %4 = icmp eq i32 %0, 0, !dbg !51
  br i1 %4, label %13, label %5, !dbg !52

5:                                                ; preds = %2
  %6 = lshr i32 %3, 1, !dbg !53
  %7 = and i32 %6, 1, !dbg !53
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !53
    #dbg_value(i32 %8, !17, !DIExpression(), !48)
  %9 = lshr i32 %3, 2, !dbg !54
  %10 = and i32 %9, 1, !dbg !54
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !54
  %12 = add nsw i32 %11, %8, !dbg !55
    #dbg_value(i32 %12, !17, !DIExpression(), !48)
  br label %13, !dbg !56

13:                                               ; preds = %2, %5
  %14 = phi i32 [ %12, %5 ], [ 0, %2 ], !dbg !48
    #dbg_value(i32 %14, !17, !DIExpression(), !48)
  %15 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 9.000000e-01) #2, !dbg !57
    #dbg_value(i32 %15, !16, !DIExpression(), !48)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !58
  %17 = add nsw i32 %16, %14, !dbg !59
  ret i32 %17, !dbg !60
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b1_condloop_dom_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "331473414df9ec60dc8fe03a71b78a77")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "c", arg: 1, scope: !10, file: !8, line: 3, type: !13)
!16 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 5, type: !13)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 4, column: 13, scope: !10)
!20 = !DILocation(line: 6, column: 9, scope: !21)
!21 = distinct !DILexicalBlock(scope: !10, file: !8, line: 6, column: 9)
!22 = !DILocation(line: 6, column: 9, scope: !10)
!23 = !DILocation(line: 7, column: 14, scope: !24)
!24 = distinct !DILexicalBlock(scope: !21, file: !8, line: 6, column: 12)
!25 = !DILocation(line: 8, column: 14, scope: !24)
!26 = !DILocation(line: 8, column: 11, scope: !24)
!27 = !DILocation(line: 9, column: 5, scope: !24)
!28 = !DILocation(line: 10, column: 9, scope: !10)
!29 = !DILocation(line: 11, column: 16, scope: !10)
!30 = !DILocation(line: 11, column: 14, scope: !10)
!31 = !DILocation(line: 11, column: 5, scope: !10)
!32 = !DISubprogram(name: "cq_theta_si32", scope: !33, file: !33, line: 38, type: !34, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!33 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!34 = !DISubroutineType(types: !35)
!35 = !{!13, !13, !36}
!36 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!37 = !DISubprogram(name: "cq_measure_si32", scope: !33, file: !33, line: 83, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!38 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !39, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !44)
!39 = !DISubroutineType(types: !40)
!40 = !{!13, !13, !41}
!41 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !42, size: 64)
!42 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !43, size: 64)
!43 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!44 = !{!45, !46}
!45 = !DILocalVariable(name: "argc", arg: 1, scope: !38, file: !8, line: 13, type: !13)
!46 = !DILocalVariable(name: "argv", arg: 2, scope: !38, file: !8, line: 13, type: !41)
!47 = !DILocation(line: 0, scope: !38)
!48 = !DILocation(line: 0, scope: !10, inlinedAt: !49)
!49 = distinct !DILocation(line: 13, column: 54, scope: !38)
!50 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !49)
!51 = !DILocation(line: 6, column: 9, scope: !21, inlinedAt: !49)
!52 = !DILocation(line: 6, column: 9, scope: !10, inlinedAt: !49)
!53 = !DILocation(line: 7, column: 14, scope: !24, inlinedAt: !49)
!54 = !DILocation(line: 8, column: 14, scope: !24, inlinedAt: !49)
!55 = !DILocation(line: 8, column: 11, scope: !24, inlinedAt: !49)
!56 = !DILocation(line: 9, column: 5, scope: !24, inlinedAt: !49)
!57 = !DILocation(line: 10, column: 9, scope: !10, inlinedAt: !49)
!58 = !DILocation(line: 11, column: 16, scope: !10, inlinedAt: !49)
!59 = !DILocation(line: 11, column: 14, scope: !10, inlinedAt: !49)
!60 = !DILocation(line: 13, column: 47, scope: !38)
