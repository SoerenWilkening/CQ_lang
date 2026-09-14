; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b9_guarded_loop_dom.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b9_guarded_loop_dom.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !21)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !22
    #dbg_value(i32 %2, !16, !DIExpression(), !21)
  %3 = and i32 %0, 3, !dbg !23
    #dbg_value(i32 %3, !17, !DIExpression(), !21)
    #dbg_value(i32 0, !18, !DIExpression(), !21)
    #dbg_value(i32 1, !19, !DIExpression(), !24)
  %4 = icmp eq i32 %3, 0, !dbg !25
  br i1 %4, label %5, label %10, !dbg !27

5:                                                ; preds = %10, %1
  %6 = phi i32 [ 0, %1 ], [ %16, %10 ], !dbg !21
  %7 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2, !dbg !28
    #dbg_value(i32 %7, !16, !DIExpression(), !21)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !29
  %9 = add nsw i32 %8, %6, !dbg !30
  ret i32 %9, !dbg !31

10:                                               ; preds = %1, %10
  %11 = phi i32 [ %17, %10 ], [ 1, %1 ]
  %12 = phi i32 [ %16, %10 ], [ 0, %1 ]
    #dbg_value(i32 %11, !19, !DIExpression(), !24)
    #dbg_value(i32 %12, !18, !DIExpression(), !21)
  %13 = lshr i32 %2, %11, !dbg !32
  %14 = and i32 %13, 1, !dbg !32
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2, !dbg !32
  %16 = add nsw i32 %15, %12, !dbg !33
    #dbg_value(i32 %16, !18, !DIExpression(), !21)
  %17 = add nuw nsw i32 %11, 1, !dbg !34
    #dbg_value(i32 %17, !19, !DIExpression(), !24)
  %18 = icmp eq i32 %11, %3, !dbg !25
  br i1 %18, label %5, label %10, !dbg !27, !llvm.loop !35
}

declare !dbg !39 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !44 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !45 {
    #dbg_value(i32 %0, !52, !DIExpression(), !54)
    #dbg_value(ptr %1, !53, !DIExpression(), !54)
    #dbg_value(i32 %0, !15, !DIExpression(), !55)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !57
    #dbg_value(i32 %3, !16, !DIExpression(), !55)
  %4 = and i32 %0, 3, !dbg !58
    #dbg_value(i32 %4, !17, !DIExpression(), !55)
    #dbg_value(i32 0, !18, !DIExpression(), !55)
    #dbg_value(i32 1, !19, !DIExpression(), !59)
  %5 = icmp eq i32 %4, 0, !dbg !60
  br i1 %5, label %15, label %6, !dbg !61

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %13, %6 ], [ 1, %2 ]
  %8 = phi i32 [ %12, %6 ], [ 0, %2 ]
    #dbg_value(i32 %7, !19, !DIExpression(), !59)
    #dbg_value(i32 %8, !18, !DIExpression(), !55)
  %9 = lshr i32 %3, %7, !dbg !62
  %10 = and i32 %9, 1, !dbg !62
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2, !dbg !62
  %12 = add nsw i32 %11, %8, !dbg !63
    #dbg_value(i32 %12, !18, !DIExpression(), !55)
  %13 = add nuw nsw i32 %7, 1, !dbg !64
    #dbg_value(i32 %13, !19, !DIExpression(), !59)
  %14 = icmp eq i32 %7, %4, !dbg !60
  br i1 %14, label %15, label %6, !dbg !61, !llvm.loop !65

15:                                               ; preds = %6, %2
  %16 = phi i32 [ 0, %2 ], [ %12, %6 ], !dbg !55
  %17 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 9.000000e-01) #2, !dbg !67
    #dbg_value(i32 %17, !16, !DIExpression(), !55)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #2, !dbg !68
  %19 = add nsw i32 %18, %16, !dbg !69
  ret i32 %19, !dbg !70
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b9_guarded_loop_dom.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "10ddcc800a0fbf2ac95b812000fac1c8")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18, !19}
!15 = !DILocalVariable(name: "n", arg: 1, scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "m", scope: !10, file: !8, line: 8, type: !13)
!18 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 9, type: !13)
!19 = !DILocalVariable(name: "k", scope: !20, file: !8, line: 10, type: !13)
!20 = distinct !DILexicalBlock(scope: !10, file: !8, line: 10, column: 5)
!21 = !DILocation(line: 0, scope: !10)
!22 = !DILocation(line: 7, column: 13, scope: !10)
!23 = !DILocation(line: 8, column: 15, scope: !10)
!24 = !DILocation(line: 0, scope: !20)
!25 = !DILocation(line: 10, column: 23, scope: !26)
!26 = distinct !DILexicalBlock(scope: !20, file: !8, line: 10, column: 5)
!27 = !DILocation(line: 10, column: 5, scope: !20)
!28 = !DILocation(line: 12, column: 9, scope: !10)
!29 = !DILocation(line: 13, column: 16, scope: !10)
!30 = !DILocation(line: 13, column: 14, scope: !10)
!31 = !DILocation(line: 13, column: 5, scope: !10)
!32 = !DILocation(line: 11, column: 14, scope: !26)
!33 = !DILocation(line: 11, column: 11, scope: !26)
!34 = !DILocation(line: 10, column: 29, scope: !26)
!35 = distinct !{!35, !27, !36, !37, !38}
!36 = !DILocation(line: 11, column: 14, scope: !20)
!37 = !{!"llvm.loop.mustprogress"}
!38 = !{!"llvm.loop.unroll.disable"}
!39 = !DISubprogram(name: "cq_theta_si32", scope: !40, file: !40, line: 38, type: !41, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!40 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!41 = !DISubroutineType(types: !42)
!42 = !{!13, !13, !43}
!43 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!44 = !DISubprogram(name: "cq_measure_si32", scope: !40, file: !40, line: 83, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!45 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 15, type: !46, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !51)
!46 = !DISubroutineType(types: !47)
!47 = !{!13, !13, !48}
!48 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !49, size: 64)
!49 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !50, size: 64)
!50 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!51 = !{!52, !53}
!52 = !DILocalVariable(name: "argc", arg: 1, scope: !45, file: !8, line: 15, type: !13)
!53 = !DILocalVariable(name: "argv", arg: 2, scope: !45, file: !8, line: 15, type: !48)
!54 = !DILocation(line: 0, scope: !45)
!55 = !DILocation(line: 0, scope: !10, inlinedAt: !56)
!56 = distinct !DILocation(line: 15, column: 54, scope: !45)
!57 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !56)
!58 = !DILocation(line: 8, column: 15, scope: !10, inlinedAt: !56)
!59 = !DILocation(line: 0, scope: !20, inlinedAt: !56)
!60 = !DILocation(line: 10, column: 23, scope: !26, inlinedAt: !56)
!61 = !DILocation(line: 10, column: 5, scope: !20, inlinedAt: !56)
!62 = !DILocation(line: 11, column: 14, scope: !26, inlinedAt: !56)
!63 = !DILocation(line: 11, column: 11, scope: !26, inlinedAt: !56)
!64 = !DILocation(line: 10, column: 29, scope: !26, inlinedAt: !56)
!65 = distinct !{!65, !61, !66, !37, !38}
!66 = !DILocation(line: 11, column: 14, scope: !20, inlinedAt: !56)
!67 = !DILocation(line: 12, column: 9, scope: !10, inlinedAt: !56)
!68 = !DILocation(line: 13, column: 16, scope: !10, inlinedAt: !56)
!69 = !DILocation(line: 13, column: 14, scope: !10, inlinedAt: !56)
!70 = !DILocation(line: 15, column: 47, scope: !45)
