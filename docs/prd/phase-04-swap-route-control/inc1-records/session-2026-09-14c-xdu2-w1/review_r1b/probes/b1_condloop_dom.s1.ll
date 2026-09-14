; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b1_condloop_dom.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b1_condloop_dom.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !22)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !23
    #dbg_value(i32 %2, !16, !DIExpression(), !22)
    #dbg_value(i32 0, !17, !DIExpression(), !22)
  %3 = icmp eq i32 %0, 0, !dbg !24
  br i1 %3, label %13, label %4, !dbg !25

4:                                                ; preds = %1, %4
  %5 = phi i32 [ %11, %4 ], [ 1, %1 ]
  %6 = phi i32 [ %10, %4 ], [ 0, %1 ]
    #dbg_value(i32 %5, !18, !DIExpression(), !26)
    #dbg_value(i32 %6, !17, !DIExpression(), !22)
  %7 = lshr i32 %2, %5, !dbg !27
  %8 = and i32 %7, 1, !dbg !27
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #2, !dbg !27
  %10 = add nsw i32 %9, %6, !dbg !29
    #dbg_value(i32 %10, !17, !DIExpression(), !22)
  %11 = add nuw nsw i32 %5, 1, !dbg !30
    #dbg_value(i32 %11, !18, !DIExpression(), !26)
  %12 = icmp eq i32 %11, 3, !dbg !31
  br i1 %12, label %13, label %4, !dbg !32, !llvm.loop !33

13:                                               ; preds = %4, %1
  %14 = phi i32 [ 0, %1 ], [ %10, %4 ], !dbg !37
    #dbg_value(i32 %14, !17, !DIExpression(), !22)
  %15 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2, !dbg !38
    #dbg_value(i32 %15, !16, !DIExpression(), !22)
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #2, !dbg !39
  %17 = add nsw i32 %16, %14, !dbg !40
  ret i32 %17, !dbg !41
}

declare !dbg !42 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !47 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !48 {
    #dbg_value(i32 %0, !55, !DIExpression(), !57)
    #dbg_value(ptr %1, !56, !DIExpression(), !57)
    #dbg_value(i32 %0, !15, !DIExpression(), !58)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !60
    #dbg_value(i32 %3, !16, !DIExpression(), !58)
    #dbg_value(i32 0, !17, !DIExpression(), !58)
  %4 = icmp eq i32 %0, 0, !dbg !61
  br i1 %4, label %14, label %5, !dbg !62

5:                                                ; preds = %2, %5
  %6 = phi i32 [ %12, %5 ], [ 1, %2 ]
  %7 = phi i32 [ %11, %5 ], [ 0, %2 ]
    #dbg_value(i32 %6, !18, !DIExpression(), !63)
    #dbg_value(i32 %7, !17, !DIExpression(), !58)
  %8 = lshr i32 %3, %6, !dbg !64
  %9 = and i32 %8, 1, !dbg !64
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2, !dbg !64
  %11 = add nsw i32 %10, %7, !dbg !65
    #dbg_value(i32 %11, !17, !DIExpression(), !58)
  %12 = add nuw nsw i32 %6, 1, !dbg !66
    #dbg_value(i32 %12, !18, !DIExpression(), !63)
  %13 = icmp eq i32 %12, 3, !dbg !67
  br i1 %13, label %14, label %5, !dbg !68, !llvm.loop !69

14:                                               ; preds = %5, %2
  %15 = phi i32 [ 0, %2 ], [ %11, %5 ], !dbg !71
    #dbg_value(i32 %15, !17, !DIExpression(), !58)
  %16 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 9.000000e-01) #2, !dbg !72
    #dbg_value(i32 %16, !16, !DIExpression(), !58)
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #2, !dbg !73
  %18 = add nsw i32 %17, %15, !dbg !74
  ret i32 %18, !dbg !75
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b1_condloop_dom.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "2427c3f57ea95c66e85c69c6970138bb")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "c", arg: 1, scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 10, type: !13)
!19 = distinct !DILexicalBlock(scope: !20, file: !8, line: 10, column: 9)
!20 = distinct !DILexicalBlock(scope: !21, file: !8, line: 9, column: 12)
!21 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 9)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 7, column: 13, scope: !10)
!24 = !DILocation(line: 9, column: 9, scope: !21)
!25 = !DILocation(line: 9, column: 9, scope: !10)
!26 = !DILocation(line: 0, scope: !19)
!27 = !DILocation(line: 11, column: 18, scope: !28)
!28 = distinct !DILexicalBlock(scope: !19, file: !8, line: 10, column: 9)
!29 = !DILocation(line: 11, column: 15, scope: !28)
!30 = !DILocation(line: 10, column: 33, scope: !28)
!31 = !DILocation(line: 10, column: 27, scope: !28)
!32 = !DILocation(line: 10, column: 9, scope: !19)
!33 = distinct !{!33, !32, !34, !35, !36}
!34 = !DILocation(line: 11, column: 18, scope: !19)
!35 = !{!"llvm.loop.mustprogress"}
!36 = !{!"llvm.loop.unroll.disable"}
!37 = !DILocation(line: 8, column: 9, scope: !10)
!38 = !DILocation(line: 13, column: 9, scope: !10)
!39 = !DILocation(line: 14, column: 16, scope: !10)
!40 = !DILocation(line: 14, column: 14, scope: !10)
!41 = !DILocation(line: 14, column: 5, scope: !10)
!42 = !DISubprogram(name: "cq_theta_si32", scope: !43, file: !43, line: 38, type: !44, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!43 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!44 = !DISubroutineType(types: !45)
!45 = !{!13, !13, !46}
!46 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!47 = !DISubprogram(name: "cq_measure_si32", scope: !43, file: !43, line: 83, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!48 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 16, type: !49, scopeLine: 16, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !54)
!49 = !DISubroutineType(types: !50)
!50 = !{!13, !13, !51}
!51 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !52, size: 64)
!52 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !53, size: 64)
!53 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!54 = !{!55, !56}
!55 = !DILocalVariable(name: "argc", arg: 1, scope: !48, file: !8, line: 16, type: !13)
!56 = !DILocalVariable(name: "argv", arg: 2, scope: !48, file: !8, line: 16, type: !51)
!57 = !DILocation(line: 0, scope: !48)
!58 = !DILocation(line: 0, scope: !10, inlinedAt: !59)
!59 = distinct !DILocation(line: 16, column: 54, scope: !48)
!60 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !59)
!61 = !DILocation(line: 9, column: 9, scope: !21, inlinedAt: !59)
!62 = !DILocation(line: 9, column: 9, scope: !10, inlinedAt: !59)
!63 = !DILocation(line: 0, scope: !19, inlinedAt: !59)
!64 = !DILocation(line: 11, column: 18, scope: !28, inlinedAt: !59)
!65 = !DILocation(line: 11, column: 15, scope: !28, inlinedAt: !59)
!66 = !DILocation(line: 10, column: 33, scope: !28, inlinedAt: !59)
!67 = !DILocation(line: 10, column: 27, scope: !28, inlinedAt: !59)
!68 = !DILocation(line: 10, column: 9, scope: !19, inlinedAt: !59)
!69 = distinct !{!69, !68, !70, !35, !36}
!70 = !DILocation(line: 11, column: 18, scope: !19, inlinedAt: !59)
!71 = !DILocation(line: 8, column: 9, scope: !10, inlinedAt: !59)
!72 = !DILocation(line: 13, column: 9, scope: !10, inlinedAt: !59)
!73 = !DILocation(line: 14, column: 16, scope: !10, inlinedAt: !59)
!74 = !DILocation(line: 14, column: 14, scope: !10, inlinedAt: !59)
!75 = !DILocation(line: 16, column: 47, scope: !48)
