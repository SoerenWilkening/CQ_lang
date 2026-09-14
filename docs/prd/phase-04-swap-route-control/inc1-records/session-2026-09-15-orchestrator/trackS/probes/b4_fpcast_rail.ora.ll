; ModuleID = './b4_fpcast_rail.s1.ll'
source_filename = "b4_fpcast_rail.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @slice() local_unnamed_addr #0 !dbg !14 {
  %h = call i32 @cqrt_alloc_f64(double 5.000000e+00), !dbg !23
  call void @cqrt_ry_f64(i32 %h, double 5.000000e-01), !dbg !23
    #dbg_value(i32 %h, !18, !DIExpression(), !24)
    #dbg_value(i32 %h, !19, !DIExpression(), !24)
    #dbg_value(double 0.000000e+00, !20, !DIExpression(), !24)
    #dbg_value(i32 0, !21, !DIExpression(), !25)
  %h_cast = call i32 @cq_template_fptrunc_f64_to_f32(i32 %h), !dbg !26
  %h_cast1 = call i32 @cq_template_fpext_f32_to_f64(i32 %h_cast)
    #dbg_value(i32 0, !21, !DIExpression(), !25)
    #dbg_value(double 0.000000e+00, !20, !DIExpression(), !24)
    #dbg_value(double poison, !19, !DIExpression(), !24)
  call void @cq_template_fptrunc_f64_to_f32_unc(i32 %h_cast, i32 %h), !dbg !26
  call void @cqrt_free(i32 %h_cast), !dbg !26
  br label %3, !dbg !29

1:                                                ; preds = %3
  call void @cqrt_ry_f64(i32 %h, double 9.000000e-01), !dbg !30
    #dbg_value(i32 %h, !18, !DIExpression(), !24)
  %m = call double @cqrt_measure_f64(i32 %h), !dbg !31
  %2 = fadd double %6, %m, !dbg !32
  ret double %2, !dbg !33

3:                                                ; preds = %3, %0
  %4 = phi i32 [ 0, %0 ], [ %7, %3 ]
  %5 = phi double [ 0.000000e+00, %0 ], [ %6, %3 ]
    #dbg_value(i32 %4, !21, !DIExpression(), !25)
    #dbg_value(double %5, !20, !DIExpression(), !24)
    #dbg_value(i32 %h_cast1, !19, !DIExpression(), !24)
  %m2 = call double @cqrt_measure_f64(i32 %h_cast1), !dbg !34
  %6 = fadd double %5, %m2, !dbg !35
    #dbg_value(double %6, !20, !DIExpression(), !24)
  %7 = add nuw nsw i32 %4, 1, !dbg !36
    #dbg_value(i32 %7, !21, !DIExpression(), !25)
    #dbg_value(double poison, !19, !DIExpression(), !24)
  %8 = icmp eq i32 %4, 0, !dbg !37
  br i1 %8, label %3, label %1, !dbg !29, !llvm.loop !38
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !42 {
  %h = call i32 @cqrt_alloc_f64(double 5.000000e+00), !dbg !45
  call void @cqrt_ry_f64(i32 %h, double 5.000000e-01), !dbg !45
    #dbg_value(i32 %h, !18, !DIExpression(), !47)
    #dbg_value(i32 %h, !19, !DIExpression(), !47)
    #dbg_value(double 0.000000e+00, !20, !DIExpression(), !47)
    #dbg_value(i32 0, !21, !DIExpression(), !48)
  %h_cast = call i32 @cq_template_fptrunc_f64_to_f32(i32 %h), !dbg !49
  %h_cast1 = call i32 @cq_template_fpext_f32_to_f64(i32 %h_cast)
    #dbg_value(i32 0, !21, !DIExpression(), !48)
    #dbg_value(double 0.000000e+00, !20, !DIExpression(), !47)
    #dbg_value(double poison, !19, !DIExpression(), !47)
  call void @cq_template_fptrunc_f64_to_f32_unc(i32 %h_cast, i32 %h), !dbg !49
  call void @cqrt_free(i32 %h_cast), !dbg !49
  br label %1, !dbg !50

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %5, %1 ]
  %3 = phi double [ 0.000000e+00, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !21, !DIExpression(), !48)
    #dbg_value(double %3, !20, !DIExpression(), !47)
    #dbg_value(i32 %h_cast1, !19, !DIExpression(), !47)
  %m = call double @cqrt_measure_f64(i32 %h_cast1), !dbg !51
  %4 = fadd double %3, %m, !dbg !52
    #dbg_value(double %4, !20, !DIExpression(), !47)
  %5 = add nuw nsw i32 %2, 1, !dbg !53
    #dbg_value(i32 %5, !21, !DIExpression(), !48)
    #dbg_value(double poison, !19, !DIExpression(), !47)
  %6 = icmp eq i32 %2, 0, !dbg !54
  br i1 %6, label %1, label %7, !dbg !50, !llvm.loop !55

7:                                                ; preds = %1
  call void @cqrt_ry_f64(i32 %h, double 9.000000e-01), !dbg !57
    #dbg_value(i32 %h, !18, !DIExpression(), !47)
  %m2 = call double @cqrt_measure_f64(i32 %h), !dbg !58
  %8 = fadd double %4, %m2, !dbg !59
  %9 = fptosi double %8 to i32, !dbg !60
  ret i32 %9, !dbg !61
}

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare i32 @cq_template_fptrunc_f64_to_f32(i32)

declare i32 @cq_template_fpext_f32_to_f64(i32)

declare double @cqrt_measure_f64(i32)

declare void @cq_template_fptrunc_f64_to_f32_unc(i32, i32)

declare void @cqrt_free(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!13}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "b4_fpcast_rail.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "80c7f6aebd5a5f66fdd1b01fb85e5995")
!9 = !{!10, !11, !12}
!10 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!11 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!12 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!13 = !{!"Homebrew clang version 19.1.7"}
!14 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 6, type: !15, scopeLine: 6, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!15 = !DISubroutineType(types: !16)
!16 = !{!10}
!17 = !{!18, !19, !20, !21}
!18 = !DILocalVariable(name: "y", scope: !14, file: !8, line: 7, type: !10)
!19 = !DILocalVariable(name: "w", scope: !14, file: !8, line: 8, type: !10)
!20 = !DILocalVariable(name: "s", scope: !14, file: !8, line: 9, type: !10)
!21 = !DILocalVariable(name: "k", scope: !22, file: !8, line: 10, type: !12)
!22 = distinct !DILexicalBlock(scope: !14, file: !8, line: 10, column: 5)
!23 = !DILocation(line: 7, column: 16, scope: !14)
!24 = !DILocation(line: 0, scope: !14)
!25 = !DILocation(line: 0, scope: !22)
!26 = !DILocation(line: 11, column: 21, scope: !27)
!27 = distinct !DILexicalBlock(scope: !28, file: !8, line: 10, column: 33)
!28 = distinct !DILexicalBlock(scope: !22, file: !8, line: 10, column: 5)
!29 = !DILocation(line: 10, column: 5, scope: !22)
!30 = !DILocation(line: 14, column: 9, scope: !14)
!31 = !DILocation(line: 15, column: 16, scope: !14)
!32 = !DILocation(line: 15, column: 14, scope: !14)
!33 = !DILocation(line: 15, column: 5, scope: !14)
!34 = !DILocation(line: 12, column: 14, scope: !27)
!35 = !DILocation(line: 12, column: 11, scope: !27)
!36 = !DILocation(line: 10, column: 28, scope: !28)
!37 = !DILocation(line: 10, column: 23, scope: !28)
!38 = distinct !{!38, !29, !39, !40, !41}
!39 = !DILocation(line: 13, column: 5, scope: !22)
!40 = !{!"llvm.loop.mustprogress"}
!41 = !{!"llvm.loop.unroll.disable"}
!42 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 17, type: !43, scopeLine: 17, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!43 = !DISubroutineType(types: !44)
!44 = !{!12}
!45 = !DILocation(line: 7, column: 16, scope: !14, inlinedAt: !46)
!46 = distinct !DILocation(line: 17, column: 30, scope: !42)
!47 = !DILocation(line: 0, scope: !14, inlinedAt: !46)
!48 = !DILocation(line: 0, scope: !22, inlinedAt: !46)
!49 = !DILocation(line: 11, column: 21, scope: !27, inlinedAt: !46)
!50 = !DILocation(line: 10, column: 5, scope: !22, inlinedAt: !46)
!51 = !DILocation(line: 12, column: 14, scope: !27, inlinedAt: !46)
!52 = !DILocation(line: 12, column: 11, scope: !27, inlinedAt: !46)
!53 = !DILocation(line: 10, column: 28, scope: !28, inlinedAt: !46)
!54 = !DILocation(line: 10, column: 23, scope: !28, inlinedAt: !46)
!55 = distinct !{!55, !50, !56, !40, !41}
!56 = !DILocation(line: 13, column: 5, scope: !22, inlinedAt: !46)
!57 = !DILocation(line: 14, column: 9, scope: !14, inlinedAt: !46)
!58 = !DILocation(line: 15, column: 16, scope: !14, inlinedAt: !46)
!59 = !DILocation(line: 15, column: 14, scope: !14, inlinedAt: !46)
!60 = !DILocation(line: 17, column: 25, scope: !42)
!61 = !DILocation(line: 17, column: 18, scope: !42)
