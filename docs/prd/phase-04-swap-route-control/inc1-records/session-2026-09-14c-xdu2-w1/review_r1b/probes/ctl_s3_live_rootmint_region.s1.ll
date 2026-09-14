; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/ctl_s3_live_rootmint_region.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/ctl_s3_live_rootmint_region.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !18
    #dbg_value(i32 %1, !15, !DIExpression(), !19)
    #dbg_value(i32 1, !16, !DIExpression(), !20)
  br label %5, !dbg !21

2:                                                ; preds = %11
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !22
    #dbg_value(i32 %3, !15, !DIExpression(), !19)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #2, !dbg !23
  ret i32 %4, !dbg !24

5:                                                ; preds = %0, %11
  %6 = phi i32 [ 1, %0 ], [ %12, %11 ]
    #dbg_value(i32 %6, !16, !DIExpression(), !20)
  %7 = shl nuw nsw i32 1, %6, !dbg !25
  %8 = and i32 %7, %1, !dbg !25
  %9 = icmp eq i32 %8, 0, !dbg !25
  br i1 %9, label %11, label %10, !dbg !28

10:                                               ; preds = %5
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !29
  br label %11, !dbg !29

11:                                               ; preds = %5, %10
  %12 = add nuw nsw i32 %6, 1, !dbg !30
    #dbg_value(i32 %12, !16, !DIExpression(), !20)
  %13 = icmp eq i32 %12, 3, !dbg !31
  br i1 %13, label %2, label %5, !dbg !21, !llvm.loop !32
}

declare !dbg !36 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !41 void @cq_phi(double noundef) local_unnamed_addr #1

declare !dbg !44 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !47 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !48
    #dbg_value(i32 %1, !15, !DIExpression(), !50)
    #dbg_value(i32 1, !16, !DIExpression(), !51)
  br label %2, !dbg !52

2:                                                ; preds = %8, %0
  %3 = phi i32 [ 1, %0 ], [ %9, %8 ]
    #dbg_value(i32 %3, !16, !DIExpression(), !51)
  %4 = shl nuw nsw i32 1, %3, !dbg !53
  %5 = and i32 %4, %1, !dbg !53
  %6 = icmp eq i32 %5, 0, !dbg !53
  br i1 %6, label %8, label %7, !dbg !54

7:                                                ; preds = %2
  tail call void @cq_phi(double noundef 3.000000e-01) #2, !dbg !55
  br label %8, !dbg !55

8:                                                ; preds = %7, %2
  %9 = add nuw nsw i32 %3, 1, !dbg !56
    #dbg_value(i32 %9, !16, !DIExpression(), !51)
  %10 = icmp eq i32 %9, 3, !dbg !57
  br i1 %10, label %11, label %2, !dbg !52, !llvm.loop !58

11:                                               ; preds = %8
  %12 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 9.000000e-01) #2, !dbg !60
    #dbg_value(i32 %12, !15, !DIExpression(), !50)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #2, !dbg !61
  ret i32 %13, !dbg !62
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/ctl_s3_live_rootmint_region.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "c97d6c736b8ef5f9435837ab194802e5")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "k", scope: !17, file: !8, line: 8, type: !13)
!17 = distinct !DILexicalBlock(scope: !10, file: !8, line: 8, column: 5)
!18 = !DILocation(line: 7, column: 13, scope: !10)
!19 = !DILocation(line: 0, scope: !10)
!20 = !DILocation(line: 0, scope: !17)
!21 = !DILocation(line: 8, column: 5, scope: !17)
!22 = !DILocation(line: 10, column: 9, scope: !10)
!23 = !DILocation(line: 11, column: 12, scope: !10)
!24 = !DILocation(line: 11, column: 5, scope: !10)
!25 = !DILocation(line: 9, column: 22, scope: !26)
!26 = distinct !DILexicalBlock(scope: !27, file: !8, line: 9, column: 13)
!27 = distinct !DILexicalBlock(scope: !17, file: !8, line: 8, column: 5)
!28 = !DILocation(line: 9, column: 13, scope: !27)
!29 = !DILocation(line: 9, column: 27, scope: !26)
!30 = !DILocation(line: 8, column: 29, scope: !27)
!31 = !DILocation(line: 8, column: 23, scope: !27)
!32 = distinct !{!32, !21, !33, !34, !35}
!33 = !DILocation(line: 9, column: 37, scope: !17)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.unroll.disable"}
!36 = !DISubprogram(name: "cq_theta_si32", scope: !37, file: !37, line: 38, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!38 = !DISubroutineType(types: !39)
!39 = !{!13, !13, !40}
!40 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!41 = !DISubprogram(name: "cq_phi", scope: !37, file: !37, line: 73, type: !42, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = !DISubroutineType(types: !43)
!43 = !{null, !40}
!44 = !DISubprogram(name: "cq_measure_si32", scope: !37, file: !37, line: 83, type: !45, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = !DISubroutineType(types: !46)
!46 = !{!13, !13}
!47 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!48 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !49)
!49 = distinct !DILocation(line: 13, column: 25, scope: !47)
!50 = !DILocation(line: 0, scope: !10, inlinedAt: !49)
!51 = !DILocation(line: 0, scope: !17, inlinedAt: !49)
!52 = !DILocation(line: 8, column: 5, scope: !17, inlinedAt: !49)
!53 = !DILocation(line: 9, column: 22, scope: !26, inlinedAt: !49)
!54 = !DILocation(line: 9, column: 13, scope: !27, inlinedAt: !49)
!55 = !DILocation(line: 9, column: 27, scope: !26, inlinedAt: !49)
!56 = !DILocation(line: 8, column: 29, scope: !27, inlinedAt: !49)
!57 = !DILocation(line: 8, column: 23, scope: !27, inlinedAt: !49)
!58 = distinct !{!58, !52, !59, !34, !35}
!59 = !DILocation(line: 9, column: 37, scope: !17, inlinedAt: !49)
!60 = !DILocation(line: 10, column: 9, scope: !10, inlinedAt: !49)
!61 = !DILocation(line: 11, column: 12, scope: !10, inlinedAt: !49)
!62 = !DILocation(line: 13, column: 18, scope: !47)
