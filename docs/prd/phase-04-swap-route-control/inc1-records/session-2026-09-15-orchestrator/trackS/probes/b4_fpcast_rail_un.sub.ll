; ModuleID = './b4_fpcast_rail_un.s1.ll'
source_filename = "b4_fpcast_rail_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @slice() local_unnamed_addr #0 !dbg !14 {
  %h = call i32 @cqrt_alloc_f64(double 5.000000e+00), !dbg !21
  call void @cqrt_ry_f64(i32 %h, double 5.000000e-01), !dbg !21
    #dbg_value(i32 %h, !18, !DIExpression(), !22)
    #dbg_value(i32 %h, !19, !DIExpression(), !22)
    #dbg_value(double 0.000000e+00, !20, !DIExpression(), !22)
  %h_cast = call i32 @cq_template_fptrunc_f64_to_f32(i32 %h), !dbg !23
  %h_cast1 = call i32 @cq_template_fpext_f32_to_f64(i32 %h_cast), !dbg !24
    #dbg_value(i32 %h_cast1, !19, !DIExpression(), !22)
  call void @cq_template_fptrunc_f64_to_f32_unc(i32 %h_cast, i32 %h), !dbg !23
  call void @cqrt_free(i32 %h_cast), !dbg !23
  %m = call double @cqrt_measure_f64(i32 %h_cast1), !dbg !25
  %1 = fadd double %m, 0.000000e+00, !dbg !26
    #dbg_value(double %1, !20, !DIExpression(), !22)
    #dbg_value(i32 %h_cast1, !19, !DIExpression(), !22)
  %m2 = call double @cqrt_measure_f64(i32 %h_cast1), !dbg !27
  %2 = fadd double %1, %m2, !dbg !28
    #dbg_value(double %2, !20, !DIExpression(), !22)
  call void @cqrt_ry_f64(i32 %h, double 9.000000e-01), !dbg !29
    #dbg_value(i32 %h, !18, !DIExpression(), !22)
  %m3 = call double @cqrt_measure_f64(i32 %h), !dbg !30
  %3 = fadd double %2, %m3, !dbg !31
  ret double %3, !dbg !32
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !33 {
  %h = call i32 @cqrt_alloc_f64(double 5.000000e+00), !dbg !36
  call void @cqrt_ry_f64(i32 %h, double 5.000000e-01), !dbg !36
    #dbg_value(i32 %h, !18, !DIExpression(), !38)
    #dbg_value(i32 %h, !19, !DIExpression(), !38)
    #dbg_value(double 0.000000e+00, !20, !DIExpression(), !38)
  %h_cast = call i32 @cq_template_fptrunc_f64_to_f32(i32 %h), !dbg !39
  %h_cast1 = call i32 @cq_template_fpext_f32_to_f64(i32 %h_cast), !dbg !40
    #dbg_value(i32 %h_cast1, !19, !DIExpression(), !38)
  call void @cq_template_fptrunc_f64_to_f32_unc(i32 %h_cast, i32 %h), !dbg !39
  call void @cqrt_free(i32 %h_cast), !dbg !39
  %m = call double @cqrt_measure_f64(i32 %h_cast1), !dbg !41
  %1 = fadd double %m, 0.000000e+00, !dbg !42
    #dbg_value(double %1, !20, !DIExpression(), !38)
    #dbg_value(i32 %h_cast1, !19, !DIExpression(), !38)
  %m2 = call double @cqrt_measure_f64(i32 %h_cast1), !dbg !43
  %2 = fadd double %1, %m2, !dbg !44
    #dbg_value(double %2, !20, !DIExpression(), !38)
  call void @cqrt_ry_f64(i32 %h, double 9.000000e-01), !dbg !45
    #dbg_value(i32 %h, !18, !DIExpression(), !38)
  %m3 = call double @cqrt_measure_f64(i32 %h), !dbg !46
  %3 = fadd double %2, %m3, !dbg !47
  %4 = fptosi double %3 to i32, !dbg !48
  ret i32 %4, !dbg !49
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
!8 = !DIFile(filename: "b4_fpcast_rail_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_S/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackS/probes", checksumkind: CSK_MD5, checksum: "42c7536b8b529376a550fde29776119f")
!9 = !{!10, !11, !12}
!10 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!11 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!12 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!13 = !{!"Homebrew clang version 19.1.7"}
!14 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !15, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!15 = !DISubroutineType(types: !16)
!16 = !{!10}
!17 = !{!18, !19, !20}
!18 = !DILocalVariable(name: "y", scope: !14, file: !8, line: 3, type: !10)
!19 = !DILocalVariable(name: "w", scope: !14, file: !8, line: 4, type: !10)
!20 = !DILocalVariable(name: "s", scope: !14, file: !8, line: 5, type: !10)
!21 = !DILocation(line: 3, column: 16, scope: !14)
!22 = !DILocation(line: 0, scope: !14)
!23 = !DILocation(line: 6, column: 17, scope: !14)
!24 = !DILocation(line: 6, column: 9, scope: !14)
!25 = !DILocation(line: 6, column: 32, scope: !14)
!26 = !DILocation(line: 6, column: 29, scope: !14)
!27 = !DILocation(line: 7, column: 32, scope: !14)
!28 = !DILocation(line: 7, column: 29, scope: !14)
!29 = !DILocation(line: 8, column: 9, scope: !14)
!30 = !DILocation(line: 9, column: 16, scope: !14)
!31 = !DILocation(line: 9, column: 14, scope: !14)
!32 = !DILocation(line: 9, column: 5, scope: !14)
!33 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 11, type: !34, scopeLine: 11, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!34 = !DISubroutineType(types: !35)
!35 = !{!12}
!36 = !DILocation(line: 3, column: 16, scope: !14, inlinedAt: !37)
!37 = distinct !DILocation(line: 11, column: 30, scope: !33)
!38 = !DILocation(line: 0, scope: !14, inlinedAt: !37)
!39 = !DILocation(line: 6, column: 17, scope: !14, inlinedAt: !37)
!40 = !DILocation(line: 6, column: 9, scope: !14, inlinedAt: !37)
!41 = !DILocation(line: 6, column: 32, scope: !14, inlinedAt: !37)
!42 = !DILocation(line: 6, column: 29, scope: !14, inlinedAt: !37)
!43 = !DILocation(line: 7, column: 32, scope: !14, inlinedAt: !37)
!44 = !DILocation(line: 7, column: 29, scope: !14, inlinedAt: !37)
!45 = !DILocation(line: 8, column: 9, scope: !14, inlinedAt: !37)
!46 = !DILocation(line: 9, column: 16, scope: !14, inlinedAt: !37)
!47 = !DILocation(line: 9, column: 14, scope: !14, inlinedAt: !37)
!48 = !DILocation(line: 11, column: 25, scope: !33)
!49 = !DILocation(line: 11, column: 18, scope: !33)
