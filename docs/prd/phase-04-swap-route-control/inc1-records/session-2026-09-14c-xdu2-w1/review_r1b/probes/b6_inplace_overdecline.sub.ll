; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b6_inplace_overdecline.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/review_r1b/probes/b6_inplace_overdecline.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 %0, !15, !DIExpression(), !20)
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !21
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !21
    #dbg_value(i32 %h, !16, !DIExpression(), !20)
  %2 = and i32 %0, 3, !dbg !22
    #dbg_value(i32 %2, !17, !DIExpression(), !20)
    #dbg_value(i32 0, !18, !DIExpression(), !23)
    #dbg_value(i32 %h, !16, !DIExpression(), !20)
  %3 = icmp eq i32 %2, 0, !dbg !24
  br i1 %3, label %4, label %5, !dbg !26

4:                                                ; preds = %5, %1
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !27
    #dbg_value(i32 %h, !16, !DIExpression(), !20)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !28
  ret i32 %m, !dbg !29

5:                                                ; preds = %5, %1
  %6 = phi i32 [ %7, %5 ], [ 0, %1 ]
    #dbg_value(i32 %6, !18, !DIExpression(), !23)
    #dbg_value(i32 %h, !16, !DIExpression(), !20)
  call void @cqrt_xorc_i32(i32 %h, i32 %6), !dbg !30
    #dbg_value(i32 %h, !16, !DIExpression(), !20)
  %7 = add nuw nsw i32 %6, 1, !dbg !31
    #dbg_value(i32 %7, !18, !DIExpression(), !23)
  %8 = icmp eq i32 %7, %2, !dbg !24
  br i1 %8, label %4, label %5, !dbg !26, !llvm.loop !32
}

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 !dbg !36 {
    #dbg_value(i32 %0, !43, !DIExpression(), !45)
    #dbg_value(ptr %1, !44, !DIExpression(), !45)
    #dbg_value(i32 %0, !15, !DIExpression(), !46)
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !48
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !48
    #dbg_value(i32 %h, !16, !DIExpression(), !46)
  %3 = and i32 %0, 3, !dbg !49
    #dbg_value(i32 %3, !17, !DIExpression(), !46)
    #dbg_value(i32 0, !18, !DIExpression(), !50)
    #dbg_value(i32 %h, !16, !DIExpression(), !46)
  %4 = icmp eq i32 %3, 0, !dbg !51
  br i1 %4, label %9, label %5, !dbg !52

5:                                                ; preds = %5, %2
  %6 = phi i32 [ %7, %5 ], [ 0, %2 ]
    #dbg_value(i32 %6, !18, !DIExpression(), !50)
    #dbg_value(i32 %h, !16, !DIExpression(), !46)
  call void @cqrt_xorc_i32(i32 %h, i32 %6), !dbg !53
    #dbg_value(i32 %h, !16, !DIExpression(), !46)
  %7 = add nuw nsw i32 %6, 1, !dbg !54
    #dbg_value(i32 %7, !18, !DIExpression(), !50)
  %8 = icmp eq i32 %7, %3, !dbg !51
  br i1 %8, label %9, label %5, !dbg !52, !llvm.loop !55

9:                                                ; preds = %5, %2
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !57
    #dbg_value(i32 %h, !16, !DIExpression(), !46)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !58
  ret i32 %m, !dbg !59
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_xorc_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

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
!36 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 14, type: !37, scopeLine: 14, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !42)
!37 = !DISubroutineType(types: !38)
!38 = !{!13, !13, !39}
!39 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !40, size: 64)
!40 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !41, size: 64)
!41 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!42 = !{!43, !44}
!43 = !DILocalVariable(name: "argc", arg: 1, scope: !36, file: !8, line: 14, type: !13)
!44 = !DILocalVariable(name: "argv", arg: 2, scope: !36, file: !8, line: 14, type: !39)
!45 = !DILocation(line: 0, scope: !36)
!46 = !DILocation(line: 0, scope: !10, inlinedAt: !47)
!47 = distinct !DILocation(line: 14, column: 54, scope: !36)
!48 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !47)
!49 = !DILocation(line: 8, column: 15, scope: !10, inlinedAt: !47)
!50 = !DILocation(line: 0, scope: !19, inlinedAt: !47)
!51 = !DILocation(line: 9, column: 23, scope: !25, inlinedAt: !47)
!52 = !DILocation(line: 9, column: 5, scope: !19, inlinedAt: !47)
!53 = !DILocation(line: 10, column: 11, scope: !25, inlinedAt: !47)
!54 = !DILocation(line: 9, column: 28, scope: !25, inlinedAt: !47)
!55 = distinct !{!55, !52, !56, !34, !35}
!56 = !DILocation(line: 10, column: 14, scope: !19, inlinedAt: !47)
!57 = !DILocation(line: 11, column: 9, scope: !10, inlinedAt: !47)
!58 = !DILocation(line: 12, column: 12, scope: !10, inlinedAt: !47)
!59 = !DILocation(line: 14, column: 47, scope: !36)
