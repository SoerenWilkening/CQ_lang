; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b6_inplace_overdecline.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b6_inplace_overdecline.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !20)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !21
    #dbg_value(i32 %2, !16, !DIExpression(), !20)
  %3 = and i32 %0, 3, !dbg !22
    #dbg_value(i32 %3, !17, !DIExpression(), !20)
    #dbg_value(i32 0, !18, !DIExpression(), !23)
    #dbg_value(i32 %2, !16, !DIExpression(), !20)
  %4 = icmp eq i32 %3, 0, !dbg !24
  br i1 %4, label %5, label %9, !dbg !26

5:                                                ; preds = %9, %1
  %6 = phi i32 [ %2, %1 ], [ %12, %9 ], !dbg !20
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 9.000000e-01) #2, !dbg !27
    #dbg_value(i32 %7, !16, !DIExpression(), !20)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #2, !dbg !28
  ret i32 %8, !dbg !29

9:                                                ; preds = %1, %9
  %10 = phi i32 [ %13, %9 ], [ 0, %1 ]
  %11 = phi i32 [ %12, %9 ], [ %2, %1 ]
    #dbg_value(i32 %10, !18, !DIExpression(), !23)
    #dbg_value(i32 %11, !16, !DIExpression(), !20)
  %12 = xor i32 %10, %11, !dbg !30
    #dbg_value(i32 %12, !16, !DIExpression(), !20)
  %13 = add nuw nsw i32 %10, 1, !dbg !31
    #dbg_value(i32 %13, !18, !DIExpression(), !23)
  %14 = icmp eq i32 %13, %3, !dbg !24
  br i1 %14, label %5, label %9, !dbg !26, !llvm.loop !32
}

declare !dbg !36 i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare !dbg !41 i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !42 {
    #dbg_value(i32 %0, !49, !DIExpression(), !51)
    #dbg_value(ptr %1, !50, !DIExpression(), !51)
    #dbg_value(i32 %0, !15, !DIExpression(), !52)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 5, double noundef 5.000000e-01) #2, !dbg !54
    #dbg_value(i32 %3, !16, !DIExpression(), !52)
  %4 = and i32 %0, 3, !dbg !55
    #dbg_value(i32 %4, !17, !DIExpression(), !52)
    #dbg_value(i32 0, !18, !DIExpression(), !56)
    #dbg_value(i32 %3, !16, !DIExpression(), !52)
  %5 = icmp eq i32 %4, 0, !dbg !57
  br i1 %5, label %12, label %6, !dbg !58

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %9, %6 ], [ %3, %2 ]
    #dbg_value(i32 %7, !18, !DIExpression(), !56)
    #dbg_value(i32 %8, !16, !DIExpression(), !52)
  %9 = xor i32 %8, %7, !dbg !59
    #dbg_value(i32 %9, !16, !DIExpression(), !52)
  %10 = add nuw nsw i32 %7, 1, !dbg !60
    #dbg_value(i32 %10, !18, !DIExpression(), !56)
  %11 = icmp eq i32 %10, %4, !dbg !57
  br i1 %11, label %12, label %6, !dbg !58, !llvm.loop !61

12:                                               ; preds = %6, %2
  %13 = phi i32 [ %3, %2 ], [ %9, %6 ], !dbg !52
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 9.000000e-01) #2, !dbg !63
    #dbg_value(i32 %14, !16, !DIExpression(), !52)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #2, !dbg !64
  ret i32 %15, !dbg !65
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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b6_inplace_overdecline.c", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "34f92b20c61590c57d1136165361361f")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17, !18}
!15 = !DILocalVariable(name: "n", arg: 1, scope: !10, file: !8, line: 6, type: !13)
!16 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!17 = !DILocalVariable(name: "m", scope: !10, file: !8, line: 8, type: !13)
!18 = !DILocalVariable(name: "k", scope: !19, file: !8, line: 9, type: !13)
!19 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 7, column: 13, scope: !10)
!22 = !DILocation(line: 8, column: 15, scope: !10)
!23 = !DILocation(line: 0, scope: !19)
!24 = !DILocation(line: 9, column: 23, scope: !25)
!25 = distinct !DILexicalBlock(scope: !19, file: !8, line: 9, column: 5)
!26 = !DILocation(line: 9, column: 5, scope: !19)
!27 = !DILocation(line: 11, column: 9, scope: !10)
!28 = !DILocation(line: 12, column: 12, scope: !10)
!29 = !DILocation(line: 12, column: 5, scope: !10)
!30 = !DILocation(line: 10, column: 11, scope: !25)
!31 = !DILocation(line: 9, column: 28, scope: !25)
!32 = distinct !{!32, !26, !33, !34, !35}
!33 = !DILocation(line: 10, column: 14, scope: !19)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.unroll.disable"}
!36 = !DISubprogram(name: "cq_theta_si32", scope: !37, file: !37, line: 38, type: !38, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!37 = !DIFile(filename: "include/CQ.h", directory: "/Users/sorenwilkening/Desktop/CQ_rev_b", checksumkind: CSK_MD5, checksum: "e4ac26756895102693b18b6c15f94d39")
!38 = !DISubroutineType(types: !39)
!39 = !{!13, !13, !40}
!40 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!41 = !DISubprogram(name: "cq_measure_si32", scope: !37, file: !37, line: 83, type: !11, flags: DIFlagPrototyped, spFlags: DISPFlagOptimized)
!42 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 14, type: !43, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !48)
!43 = !DISubroutineType(types: !44)
!44 = !{!13, !13, !45}
!45 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !46, size: 64)
!46 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !47, size: 64)
!47 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!48 = !{!49, !50}
!49 = !DILocalVariable(name: "argc", arg: 1, scope: !42, file: !8, line: 14, type: !13)
!50 = !DILocalVariable(name: "argv", arg: 2, scope: !42, file: !8, line: 14, type: !45)
!51 = !DILocation(line: 0, scope: !42)
!52 = !DILocation(line: 0, scope: !10, inlinedAt: !53)
!53 = distinct !DILocation(line: 14, column: 54, scope: !42)
!54 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !53)
!55 = !DILocation(line: 8, column: 15, scope: !10, inlinedAt: !53)
!56 = !DILocation(line: 0, scope: !19, inlinedAt: !53)
!57 = !DILocation(line: 9, column: 23, scope: !25, inlinedAt: !53)
!58 = !DILocation(line: 9, column: 5, scope: !19, inlinedAt: !53)
!59 = !DILocation(line: 10, column: 11, scope: !25, inlinedAt: !53)
!60 = !DILocation(line: 9, column: 28, scope: !25, inlinedAt: !53)
!61 = distinct !{!61, !58, !62, !34, !35}
!62 = !DILocation(line: 10, column: 14, scope: !19, inlinedAt: !53)
!63 = !DILocation(line: 11, column: 9, scope: !10, inlinedAt: !53)
!64 = !DILocation(line: 12, column: 12, scope: !10, inlinedAt: !53)
!65 = !DILocation(line: 14, column: 47, scope: !42)
