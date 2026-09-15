; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/r2_two_functions.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r2_two_functions.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ka() local_unnamed_addr #0 !dbg !10 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !19
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !19
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
    #dbg_value(i32 0, !16, !DIExpression(), !20)
    #dbg_value(i32 1, !17, !DIExpression(), !21)
  br label %3, !dbg !22

1:                                                ; preds = %3
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !23
    #dbg_value(i32 %h, !15, !DIExpression(), !20)
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !24
  %2 = add nsw i32 %m, %6, !dbg !25
  ret i32 %2, !dbg !26

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 1, %0 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %6, %3 ]
    #dbg_value(i32 %4, !17, !DIExpression(), !21)
    #dbg_value(i32 %5, !16, !DIExpression(), !20)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %4), !dbg !27
  %h_op1 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !27
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %4), !dbg !27
  call void @cqrt_free(i32 %h_op), !dbg !27
  %m2 = call i32 @cqrt_measure_i32(i32 %h_op1), !dbg !27
  %6 = add nsw i32 %m2, %5, !dbg !29
    #dbg_value(i32 %6, !16, !DIExpression(), !20)
  %7 = add nuw nsw i32 %4, 1, !dbg !30
    #dbg_value(i32 %7, !17, !DIExpression(), !21)
  %8 = icmp eq i32 %7, 3, !dbg !31
  br i1 %8, label %1, label %3, !dbg !22, !llvm.loop !32
}

; Function Attrs: nounwind ssp uwtable
define i32 @kb() local_unnamed_addr #0 !dbg !36 {
  %h = call i32 @cqrt_alloc_i32(i32 6), !dbg !43
  call void @cqrt_ry_i32(i32 %h, double 4.000000e-01), !dbg !43
    #dbg_value(i32 %h, !38, !DIExpression(), !44)
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3), !dbg !45
    #dbg_value(i32 %h_op, !39, !DIExpression(), !44)
    #dbg_value(i32 0, !40, !DIExpression(), !44)
    #dbg_value(i32 1, !41, !DIExpression(), !46)
  br label %3, !dbg !47

1:                                                ; preds = %3
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !48
  %2 = add nsw i32 %m, %6, !dbg !49
  ret i32 %2, !dbg !50

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 1, %0 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %6, %3 ]
    #dbg_value(i32 %4, !41, !DIExpression(), !46)
    #dbg_value(i32 %5, !40, !DIExpression(), !44)
  %h_op1 = call i32 @cq_template_lshr_i32_hl(i32 %h_op, i32 %4), !dbg !51
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op1, i32 1), !dbg !51
  %m3 = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !51
  %6 = add nsw i32 %m3, %5, !dbg !53
    #dbg_value(i32 %6, !40, !DIExpression(), !44)
  %7 = add nuw nsw i32 %4, 1, !dbg !54
    #dbg_value(i32 %7, !41, !DIExpression(), !46)
  %8 = icmp eq i32 %7, 3, !dbg !55
  br i1 %8, label %1, label %3, !dbg !47, !llvm.loop !56
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !58 {
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !59
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !59
    #dbg_value(i32 %h, !15, !DIExpression(), !61)
    #dbg_value(i32 0, !16, !DIExpression(), !61)
    #dbg_value(i32 1, !17, !DIExpression(), !62)
  br label %1, !dbg !63

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 1, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !17, !DIExpression(), !62)
    #dbg_value(i32 %3, !16, !DIExpression(), !61)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 %2), !dbg !64
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !64
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 %2), !dbg !64
  call void @cqrt_free(i32 %h_op), !dbg !64
  %m = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !64
  %4 = add nsw i32 %m, %3, !dbg !65
    #dbg_value(i32 %4, !16, !DIExpression(), !61)
  %5 = add nuw nsw i32 %2, 1, !dbg !66
    #dbg_value(i32 %5, !17, !DIExpression(), !62)
  %6 = icmp eq i32 %5, 3, !dbg !67
  br i1 %6, label %7, label %1, !dbg !63, !llvm.loop !68

7:                                                ; preds = %1
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !70
    #dbg_value(i32 %h, !15, !DIExpression(), !61)
  %m6 = call i32 @cqrt_measure_i32(i32 %h), !dbg !71
  %h1 = call i32 @cqrt_alloc_i32(i32 6), !dbg !72
  call void @cqrt_ry_i32(i32 %h1, double 4.000000e-01), !dbg !72
    #dbg_value(i32 %h1, !38, !DIExpression(), !74)
  %h_op3 = call i32 @cq_template_mul_i32_hl(i32 %h1, i32 3), !dbg !75
    #dbg_value(i32 %h_op3, !39, !DIExpression(), !74)
    #dbg_value(i32 0, !40, !DIExpression(), !74)
    #dbg_value(i32 1, !41, !DIExpression(), !76)
  br label %8, !dbg !77

8:                                                ; preds = %8, %7
  %9 = phi i32 [ 1, %7 ], [ %12, %8 ]
  %10 = phi i32 [ 0, %7 ], [ %11, %8 ]
    #dbg_value(i32 %9, !41, !DIExpression(), !76)
    #dbg_value(i32 %10, !40, !DIExpression(), !74)
  %h_op4 = call i32 @cq_template_lshr_i32_hl(i32 %h_op3, i32 %9), !dbg !78
  %h_op5 = call i32 @cq_template_and_i32_hl(i32 %h_op4, i32 1), !dbg !78
  %m7 = call i32 @cqrt_measure_i32(i32 %h_op5), !dbg !78
  %11 = add nsw i32 %m7, %10, !dbg !79
    #dbg_value(i32 %11, !40, !DIExpression(), !74)
  %12 = add nuw nsw i32 %9, 1, !dbg !80
    #dbg_value(i32 %12, !41, !DIExpression(), !76)
  %13 = icmp eq i32 %12, 3, !dbg !81
  br i1 %13, label %14, label %8, !dbg !77, !llvm.loop !82

14:                                               ; preds = %8
  %m8 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !84
  %15 = add i32 %m6, %4, !dbg !85
  %16 = add i32 %15, %11, !dbg !86
  %17 = add i32 %16, %m8, !dbg !87
  ret i32 %17, !dbg !88
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_mul_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/r2_two_functions.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "1453bf4233c4e8c9750fd80566a77641")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "ka", scope: !8, file: !8, line: 6, type: !11, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16, !17}
!15 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 7, type: !13)
!16 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 8, type: !13)
!17 = !DILocalVariable(name: "k", scope: !18, file: !8, line: 9, type: !13)
!18 = distinct !DILexicalBlock(scope: !10, file: !8, line: 9, column: 5)
!19 = !DILocation(line: 7, column: 13, scope: !10)
!20 = !DILocation(line: 0, scope: !10)
!21 = !DILocation(line: 0, scope: !18)
!22 = !DILocation(line: 9, column: 5, scope: !18)
!23 = !DILocation(line: 10, column: 9, scope: !10)
!24 = !DILocation(line: 11, column: 16, scope: !10)
!25 = !DILocation(line: 11, column: 14, scope: !10)
!26 = !DILocation(line: 11, column: 5, scope: !10)
!27 = !DILocation(line: 9, column: 39, scope: !28)
!28 = distinct !DILexicalBlock(scope: !18, file: !8, line: 9, column: 5)
!29 = !DILocation(line: 9, column: 36, scope: !28)
!30 = !DILocation(line: 9, column: 29, scope: !28)
!31 = !DILocation(line: 9, column: 23, scope: !28)
!32 = distinct !{!32, !22, !33, !34, !35}
!33 = !DILocation(line: 9, column: 39, scope: !18)
!34 = !{!"llvm.loop.mustprogress"}
!35 = !{!"llvm.loop.unroll.disable"}
!36 = distinct !DISubprogram(name: "kb", scope: !8, file: !8, line: 13, type: !11, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !37)
!37 = !{!38, !39, !40, !41}
!38 = !DILocalVariable(name: "y", scope: !36, file: !8, line: 14, type: !13)
!39 = !DILocalVariable(name: "p", scope: !36, file: !8, line: 15, type: !13)
!40 = !DILocalVariable(name: "s", scope: !36, file: !8, line: 16, type: !13)
!41 = !DILocalVariable(name: "k", scope: !42, file: !8, line: 17, type: !13)
!42 = distinct !DILexicalBlock(scope: !36, file: !8, line: 17, column: 5)
!43 = !DILocation(line: 14, column: 13, scope: !36)
!44 = !DILocation(line: 0, scope: !36)
!45 = !DILocation(line: 15, column: 15, scope: !36)
!46 = !DILocation(line: 0, scope: !42)
!47 = !DILocation(line: 17, column: 5, scope: !42)
!48 = !DILocation(line: 18, column: 16, scope: !36)
!49 = !DILocation(line: 18, column: 14, scope: !36)
!50 = !DILocation(line: 18, column: 5, scope: !36)
!51 = !DILocation(line: 17, column: 39, scope: !52)
!52 = distinct !DILexicalBlock(scope: !42, file: !8, line: 17, column: 5)
!53 = !DILocation(line: 17, column: 36, scope: !52)
!54 = !DILocation(line: 17, column: 29, scope: !52)
!55 = !DILocation(line: 17, column: 23, scope: !52)
!56 = distinct !{!56, !47, !57, !34, !35}
!57 = !DILocation(line: 17, column: 39, scope: !42)
!58 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 20, type: !11, scopeLine: 20, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!59 = !DILocation(line: 7, column: 13, scope: !10, inlinedAt: !60)
!60 = distinct !DILocation(line: 20, column: 25, scope: !58)
!61 = !DILocation(line: 0, scope: !10, inlinedAt: !60)
!62 = !DILocation(line: 0, scope: !18, inlinedAt: !60)
!63 = !DILocation(line: 9, column: 5, scope: !18, inlinedAt: !60)
!64 = !DILocation(line: 9, column: 39, scope: !28, inlinedAt: !60)
!65 = !DILocation(line: 9, column: 36, scope: !28, inlinedAt: !60)
!66 = !DILocation(line: 9, column: 29, scope: !28, inlinedAt: !60)
!67 = !DILocation(line: 9, column: 23, scope: !28, inlinedAt: !60)
!68 = distinct !{!68, !63, !69, !34, !35}
!69 = !DILocation(line: 9, column: 39, scope: !18, inlinedAt: !60)
!70 = !DILocation(line: 10, column: 9, scope: !10, inlinedAt: !60)
!71 = !DILocation(line: 11, column: 16, scope: !10, inlinedAt: !60)
!72 = !DILocation(line: 14, column: 13, scope: !36, inlinedAt: !73)
!73 = distinct !DILocation(line: 20, column: 32, scope: !58)
!74 = !DILocation(line: 0, scope: !36, inlinedAt: !73)
!75 = !DILocation(line: 15, column: 15, scope: !36, inlinedAt: !73)
!76 = !DILocation(line: 0, scope: !42, inlinedAt: !73)
!77 = !DILocation(line: 17, column: 5, scope: !42, inlinedAt: !73)
!78 = !DILocation(line: 17, column: 39, scope: !52, inlinedAt: !73)
!79 = !DILocation(line: 17, column: 36, scope: !52, inlinedAt: !73)
!80 = !DILocation(line: 17, column: 29, scope: !52, inlinedAt: !73)
!81 = !DILocation(line: 17, column: 23, scope: !52, inlinedAt: !73)
!82 = distinct !{!82, !77, !83, !34, !35}
!83 = !DILocation(line: 17, column: 39, scope: !42, inlinedAt: !73)
!84 = !DILocation(line: 18, column: 16, scope: !36, inlinedAt: !73)
!85 = !DILocation(line: 18, column: 14, scope: !36, inlinedAt: !73)
!86 = !DILocation(line: 11, column: 14, scope: !10, inlinedAt: !60)
!87 = !DILocation(line: 20, column: 30, scope: !58)
!88 = !DILocation(line: 20, column: 18, scope: !58)
