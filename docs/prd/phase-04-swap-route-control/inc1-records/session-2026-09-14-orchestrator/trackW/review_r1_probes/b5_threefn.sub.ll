; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.ZtASkxKoJq/s1.ll'
source_filename = "./b5_threefn.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f_pass() local_unnamed_addr #0 !dbg !12 {
    #dbg_value(i32 0, !18, !DIExpression(), !25)
    #dbg_value(i32 0, !19, !DIExpression(), !26)
  br label %2, !dbg !27

1:                                                ; preds = %2
  ret i32 %7, !dbg !28

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %7, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %8, %2 ]
    #dbg_value(i32 %3, !18, !DIExpression(), !25)
    #dbg_value(i32 %4, !19, !DIExpression(), !26)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !29
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !29
    #dbg_value(i32 %h, !21, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !30)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !31
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !31
    #dbg_value(i32 %h1, !24, !DIExpression(), !30)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 2.000000e-01), !dbg !32
    #dbg_value(i32 %h1, !24, !DIExpression(), !30)
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !34
  %m2 = call i1 @cqrt_measure_i1(i32 %h), !dbg !35
  %5 = zext i1 %m2 to i32, !dbg !35
  %6 = add i32 %m, %3, !dbg !36
  %7 = add i32 %6, %5, !dbg !37
    #dbg_value(i32 %7, !18, !DIExpression(), !25)
  %8 = add nuw nsw i32 %4, 1, !dbg !38
    #dbg_value(i32 %8, !19, !DIExpression(), !26)
  %9 = icmp eq i32 %4, 0, !dbg !39
  br i1 %9, label %2, label %1, !dbg !27, !llvm.loop !40
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @f_mid(i32 noundef %0) local_unnamed_addr #1 !dbg !44 {
    #dbg_value(i32 %0, !48, !DIExpression(), !49)
  %2 = mul nsw i32 %0, 3, !dbg !50
  %3 = add nsw i32 %2, 1, !dbg !51
  ret i32 %3, !dbg !52
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f_fail() local_unnamed_addr #0 !dbg !53 {
    #dbg_value(i32 0, !55, !DIExpression(), !62)
    #dbg_value(i32 0, !56, !DIExpression(), !63)
  br label %2, !dbg !64

1:                                                ; preds = %2
  ret i32 %6, !dbg !65

2:                                                ; preds = %2, %0
  %3 = phi i32 [ 0, %0 ], [ %6, %2 ]
  %4 = phi i32 [ 0, %0 ], [ %7, %2 ]
    #dbg_value(i32 %3, !55, !DIExpression(), !62)
    #dbg_value(i32 %4, !56, !DIExpression(), !63)
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !66
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !66
    #dbg_value(i32 %h, !58, !DIExpression(), !67)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !68
  call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01), !dbg !68
    #dbg_value(i32 %h1, !61, !DIExpression(), !67)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 2), !dbg !69
  %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op, i32 0), !dbg !69
  call void @cqrt_x(i32 %h_cmp), !dbg !71
  call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 2.000000e-01), !dbg !72
  call void @cqrt_x(i32 %h_cmp), !dbg !71
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 0), !dbg !69
  call void @cqrt_free(i32 %h_cmp), !dbg !71
    #dbg_value(i32 %h1, !61, !DIExpression(), !67)
  %m = call i32 @cqrt_measure_i32(i32 %h1), !dbg !73
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !74
  %5 = add i32 %m, %3, !dbg !75
  %6 = add i32 %5, %m2, !dbg !76
    #dbg_value(i32 %6, !55, !DIExpression(), !62)
  %7 = add nuw nsw i32 %4, 1, !dbg !77
    #dbg_value(i32 %7, !56, !DIExpression(), !63)
  %8 = icmp eq i32 %4, 0, !dbg !78
  br i1 %8, label %2, label %1, !dbg !64, !llvm.loop !79
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #2 !dbg !81 {
  %1 = tail call i32 @f_pass(), !dbg !82
  %2 = tail call i32 @f_mid(i32 noundef 2), !dbg !83
  %3 = add nsw i32 %2, %1, !dbg !84
  %4 = tail call i32 @f_fail(), !dbg !85
  %5 = add nsw i32 %3, %4, !dbg !86
  ret i32 %5, !dbg !87
}

declare void @cqrt_x(i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare i1 @cqrt_measure_i1(i32)

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!11}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "b5_threefn.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "511002c6d37f656ff512b6b08e6512b1")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "f_pass", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./b5_threefn.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r1_probes", checksumkind: CSK_MD5, checksum: "511002c6d37f656ff512b6b08e6512b1")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !21, !24}
!18 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 4, type: !16)
!19 = !DILocalVariable(name: "k", scope: !20, file: !13, line: 5, type: !16)
!20 = distinct !DILexicalBlock(scope: !12, file: !13, line: 5, column: 5)
!21 = !DILocalVariable(name: "t", scope: !22, file: !13, line: 6, type: !10)
!22 = distinct !DILexicalBlock(scope: !23, file: !13, line: 5, column: 33)
!23 = distinct !DILexicalBlock(scope: !20, file: !13, line: 5, column: 5)
!24 = !DILocalVariable(name: "r", scope: !22, file: !13, line: 6, type: !16)
!25 = !DILocation(line: 0, scope: !12)
!26 = !DILocation(line: 0, scope: !20)
!27 = !DILocation(line: 5, column: 5, scope: !20)
!28 = !DILocation(line: 10, column: 5, scope: !12)
!29 = !DILocation(line: 6, column: 18, scope: !22)
!30 = !DILocation(line: 0, scope: !22)
!31 = !DILocation(line: 6, column: 50, scope: !22)
!32 = !DILocation(line: 7, column: 20, scope: !33)
!33 = distinct !DILexicalBlock(scope: !22, file: !13, line: 7, column: 13)
!34 = !DILocation(line: 8, column: 14, scope: !22)
!35 = !DILocation(line: 8, column: 30, scope: !22)
!36 = !DILocation(line: 8, column: 28, scope: !22)
!37 = !DILocation(line: 8, column: 11, scope: !22)
!38 = !DILocation(line: 5, column: 28, scope: !23)
!39 = !DILocation(line: 5, column: 23, scope: !23)
!40 = distinct !{!40, !27, !41, !42, !43}
!41 = !DILocation(line: 9, column: 5, scope: !20)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = distinct !DISubprogram(name: "f_mid", scope: !13, file: !13, line: 12, type: !45, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !47)
!45 = !DISubroutineType(types: !46)
!46 = !{!16, !16}
!47 = !{!48}
!48 = !DILocalVariable(name: "x", arg: 1, scope: !44, file: !13, line: 12, type: !16)
!49 = !DILocation(line: 0, scope: !44)
!50 = !DILocation(line: 12, column: 55, scope: !44)
!51 = !DILocation(line: 12, column: 59, scope: !44)
!52 = !DILocation(line: 12, column: 46, scope: !44)
!53 = distinct !DISubprogram(name: "f_fail", scope: !13, file: !13, line: 13, type: !14, scopeLine: 13, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !54)
!54 = !{!55, !56, !58, !61}
!55 = !DILocalVariable(name: "s", scope: !53, file: !13, line: 14, type: !16)
!56 = !DILocalVariable(name: "k", scope: !57, file: !13, line: 15, type: !16)
!57 = distinct !DILexicalBlock(scope: !53, file: !13, line: 15, column: 5)
!58 = !DILocalVariable(name: "u", scope: !59, file: !13, line: 16, type: !16)
!59 = distinct !DILexicalBlock(scope: !60, file: !13, line: 15, column: 33)
!60 = distinct !DILexicalBlock(scope: !57, file: !13, line: 15, column: 5)
!61 = !DILocalVariable(name: "r", scope: !59, file: !13, line: 16, type: !16)
!62 = !DILocation(line: 0, scope: !53)
!63 = !DILocation(line: 0, scope: !57)
!64 = !DILocation(line: 15, column: 5, scope: !57)
!65 = !DILocation(line: 20, column: 5, scope: !53)
!66 = !DILocation(line: 16, column: 17, scope: !59)
!67 = !DILocation(line: 0, scope: !59)
!68 = !DILocation(line: 16, column: 43, scope: !59)
!69 = !DILocation(line: 17, column: 22, scope: !70)
!70 = distinct !DILexicalBlock(scope: !59, file: !13, line: 17, column: 13)
!71 = !DILocation(line: 17, column: 13, scope: !59)
!72 = !DILocation(line: 17, column: 31, scope: !70)
!73 = !DILocation(line: 18, column: 14, scope: !59)
!74 = !DILocation(line: 18, column: 30, scope: !59)
!75 = !DILocation(line: 18, column: 28, scope: !59)
!76 = !DILocation(line: 18, column: 11, scope: !59)
!77 = !DILocation(line: 15, column: 28, scope: !60)
!78 = !DILocation(line: 15, column: 23, scope: !60)
!79 = distinct !{!79, !64, !80, !42, !43}
!80 = !DILocation(line: 19, column: 5, scope: !57)
!81 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 22, type: !14, scopeLine: 22, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!82 = !DILocation(line: 22, column: 25, scope: !81)
!83 = !DILocation(line: 22, column: 36, scope: !81)
!84 = !DILocation(line: 22, column: 34, scope: !81)
!85 = !DILocation(line: 22, column: 47, scope: !81)
!86 = !DILocation(line: 22, column: 45, scope: !81)
!87 = !DILocation(line: 22, column: 18, scope: !81)
