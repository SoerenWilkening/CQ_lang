; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r07_widths.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r07_widths.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f() local_unnamed_addr #0 !dbg !12 {
  %h = call i32 @cqrt_alloc_i8(i8 0), !dbg !24
  call void @cqrt_ry_i8(i32 %h, double 5.000000e-01), !dbg !24
    #dbg_value(i32 %h, !16, !DIExpression(), !25)
  %h1 = call i32 @cqrt_alloc_i16(i16 0), !dbg !26
  call void @cqrt_ry_i16(i32 %h1, double 5.000000e-01), !dbg !26
    #dbg_value(i32 %h1, !18, !DIExpression(), !25)
  %h2 = call i32 @cqrt_alloc_i64(i64 0), !dbg !27
  call void @cqrt_ry_i64(i32 %h2, double 5.000000e-01), !dbg !27
    #dbg_value(i32 %h2, !20, !DIExpression(), !25)
  %h3 = call i32 @cqrt_alloc_f32(float 0.000000e+00), !dbg !28
  call void @cqrt_ry_f32(i32 %h3, double 5.000000e-01), !dbg !28
    #dbg_value(i32 %h3, !22, !DIExpression(), !25)
  %m = call i8 @cqrt_measure_i8(i32 %h), !dbg !29
  %1 = sext i8 %m to i32, !dbg !30
  %m4 = call i16 @cqrt_measure_i16(i32 %h1), !dbg !31
  %2 = sext i16 %m4 to i32, !dbg !32
  %3 = add nsw i32 %2, %1, !dbg !33
  %m5 = call i64 @cqrt_measure_i64(i32 %h2), !dbg !34
  %4 = trunc i64 %m5 to i32, !dbg !35
  %5 = add nsw i32 %3, %4, !dbg !36
  %m6 = call float @cqrt_measure_f32(i32 %h3), !dbg !37
  %6 = fptosi float %m6 to i32, !dbg !38
  %7 = add nsw i32 %5, %6, !dbg !39
  ret i32 %7, !dbg !40
}

declare void @cqrt_ry_i8(i32, double)

declare i32 @cqrt_alloc_i8(i8)

declare void @cqrt_ry_i16(i32, double)

declare i32 @cqrt_alloc_i16(i16)

declare void @cqrt_ry_i64(i32, double)

declare i32 @cqrt_alloc_i64(i64)

declare void @cqrt_ry_f32(i32, double)

declare i32 @cqrt_alloc_f32(float)

declare i8 @cqrt_measure_i8(i32)

declare i16 @cqrt_measure_i16(i32)

declare i64 @cqrt_measure_i64(i32)

declare float @cqrt_measure_f32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

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
!8 = !DIFile(filename: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r07_widths.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "93fcc6c51ef943544be68b37ba1cc26b")
!9 = !{!10}
!10 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "f", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !15)
!13 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r1_probes/r07_widths.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang", checksumkind: CSK_MD5, checksum: "93fcc6c51ef943544be68b37ba1cc26b")
!14 = !DISubroutineType(types: !9)
!15 = !{!16, !18, !20, !22}
!16 = !DILocalVariable(name: "c8", scope: !12, file: !13, line: 4, type: !17)
!17 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!18 = !DILocalVariable(name: "s16", scope: !12, file: !13, line: 4, type: !19)
!19 = !DIBasicType(name: "short", size: 16, encoding: DW_ATE_signed)
!20 = !DILocalVariable(name: "l64", scope: !12, file: !13, line: 4, type: !21)
!21 = !DIBasicType(name: "long long", size: 64, encoding: DW_ATE_signed)
!22 = !DILocalVariable(name: "f32", scope: !12, file: !13, line: 4, type: !23)
!23 = !DIBasicType(name: "float", size: 32, encoding: DW_ATE_float)
!24 = !DILocation(line: 5, column: 9, scope: !12)
!25 = !DILocation(line: 0, scope: !12)
!26 = !DILocation(line: 6, column: 9, scope: !12)
!27 = !DILocation(line: 7, column: 9, scope: !12)
!28 = !DILocation(line: 8, column: 9, scope: !12)
!29 = !DILocation(line: 9, column: 15, scope: !12)
!30 = !DILocation(line: 9, column: 10, scope: !12)
!31 = !DILocation(line: 9, column: 37, scope: !12)
!32 = !DILocation(line: 9, column: 32, scope: !12)
!33 = !DILocation(line: 9, column: 30, scope: !12)
!34 = !DILocation(line: 9, column: 60, scope: !12)
!35 = !DILocation(line: 9, column: 55, scope: !12)
!36 = !DILocation(line: 9, column: 53, scope: !12)
!37 = !DILocation(line: 9, column: 83, scope: !12)
!38 = !DILocation(line: 9, column: 78, scope: !12)
!39 = !DILocation(line: 9, column: 76, scope: !12)
!40 = !DILocation(line: 9, column: 3, scope: !12)
