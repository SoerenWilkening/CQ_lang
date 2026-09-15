; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/x2_xorc_plus_outofplace_un.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x2_xorc_plus_outofplace_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
    #dbg_declare(ptr undef, !15, !DIExpression(), !20)
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !21
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !21
    #dbg_value(i32 %h, !17, !DIExpression(), !22)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !23
  call void @cqrt_ry_i32(i32 %h1, double 3.000000e-01), !dbg !23
    #dbg_value(i32 %h1, !18, !DIExpression(), !22)
    #dbg_value(i32 0, !19, !DIExpression(), !22)
  call void @cqrt_xorc_i32(i32 %h1, i32 3), !dbg !24
    #dbg_value(i32 %h1, !18, !DIExpression(), !22)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !25
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !25
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !25
  call void @cqrt_free(i32 %h_op), !dbg !25
  %m = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !25
    #dbg_value(i32 %m, !19, !DIExpression(), !22)
  call void @cqrt_xorc_i32(i32 %h1, i32 3), !dbg !26
    #dbg_value(i32 %h1, !18, !DIExpression(), !22)
  %h_op3 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 2), !dbg !27
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h_op3, i32 1), !dbg !27
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op3, i32 %h, i32 2), !dbg !27
  call void @cqrt_free(i32 %h_op3), !dbg !27
  %m5 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !27
  %1 = add nsw i32 %m5, %m, !dbg !28
    #dbg_value(i32 %1, !19, !DIExpression(), !22)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !29
    #dbg_value(i32 %h, !17, !DIExpression(), !22)
  %m6 = call i32 @cqrt_measure_i32(i32 %h), !dbg !30
  %2 = add nsw i32 %1, %m6, !dbg !31
  %m7 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !32
  %3 = add nsw i32 %2, %m7, !dbg !33
  ret i32 %3, !dbg !34
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !35 {
    #dbg_declare(ptr undef, !15, !DIExpression(), !36)
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !38
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !38
    #dbg_value(i32 %h, !17, !DIExpression(), !39)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !40
  call void @cqrt_ry_i32(i32 %h1, double 3.000000e-01), !dbg !40
    #dbg_value(i32 %h1, !18, !DIExpression(), !39)
    #dbg_value(i32 0, !19, !DIExpression(), !39)
  call void @cqrt_xorc_i32(i32 %h1, i32 3), !dbg !41
    #dbg_value(i32 %h1, !18, !DIExpression(), !39)
  %h_op = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 1), !dbg !42
  %h_op2 = call i32 @cq_template_and_i32_hl(i32 %h_op, i32 1), !dbg !42
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op, i32 %h, i32 1), !dbg !42
  call void @cqrt_free(i32 %h_op), !dbg !42
  %m = call i32 @cqrt_measure_i32(i32 %h_op2), !dbg !42
    #dbg_value(i32 %m, !19, !DIExpression(), !39)
  call void @cqrt_xorc_i32(i32 %h1, i32 3), !dbg !43
    #dbg_value(i32 %h1, !18, !DIExpression(), !39)
  %h_op3 = call i32 @cq_template_lshr_i32_hl(i32 %h, i32 2), !dbg !44
  %h_op4 = call i32 @cq_template_and_i32_hl(i32 %h_op3, i32 1), !dbg !44
  call void @cq_template_lshr_i32_hl_unc(i32 %h_op3, i32 %h, i32 2), !dbg !44
  call void @cqrt_free(i32 %h_op3), !dbg !44
  %m5 = call i32 @cqrt_measure_i32(i32 %h_op4), !dbg !44
  %1 = add nsw i32 %m5, %m, !dbg !45
    #dbg_value(i32 %1, !19, !DIExpression(), !39)
  call void @cqrt_ry_i32(i32 %h, double 9.000000e-01), !dbg !46
    #dbg_value(i32 %h, !17, !DIExpression(), !39)
  %m6 = call i32 @cqrt_measure_i32(i32 %h), !dbg !47
  %2 = add nsw i32 %1, %m6, !dbg !48
  %m7 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !49
  %3 = add nsw i32 %2, %m7, !dbg !50
  ret i32 %3, !dbg !51
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_xorc_i32(i32, i32)

declare i32 @cq_template_lshr_i32_hl(i32, i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x2_xorc_plus_outofplace_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "731535330b8294aa5a080acc2ba95580")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 2, type: !11, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !17, !18, !19}
!15 = !DILocalVariable(name: "v", scope: !10, file: !8, line: 3, type: !16)
!16 = !DIDerivedType(tag: DW_TAG_volatile_type, baseType: !13)
!17 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 4, type: !13)
!18 = !DILocalVariable(name: "z", scope: !10, file: !8, line: 5, type: !13)
!19 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 6, type: !13)
!20 = !DILocation(line: 3, column: 18, scope: !10)
!21 = !DILocation(line: 4, column: 13, scope: !10)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 5, column: 13, scope: !10)
!24 = !DILocation(line: 7, column: 7, scope: !10)
!25 = !DILocation(line: 7, column: 18, scope: !10)
!26 = !DILocation(line: 8, column: 7, scope: !10)
!27 = !DILocation(line: 8, column: 18, scope: !10)
!28 = !DILocation(line: 8, column: 15, scope: !10)
!29 = !DILocation(line: 9, column: 9, scope: !10)
!30 = !DILocation(line: 10, column: 16, scope: !10)
!31 = !DILocation(line: 10, column: 14, scope: !10)
!32 = !DILocation(line: 10, column: 32, scope: !10)
!33 = !DILocation(line: 10, column: 30, scope: !10)
!34 = !DILocation(line: 10, column: 5, scope: !10)
!35 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 12, type: !11, scopeLine: 12, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!36 = !DILocation(line: 3, column: 18, scope: !10, inlinedAt: !37)
!37 = distinct !DILocation(line: 12, column: 25, scope: !35)
!38 = !DILocation(line: 4, column: 13, scope: !10, inlinedAt: !37)
!39 = !DILocation(line: 0, scope: !10, inlinedAt: !37)
!40 = !DILocation(line: 5, column: 13, scope: !10, inlinedAt: !37)
!41 = !DILocation(line: 7, column: 7, scope: !10, inlinedAt: !37)
!42 = !DILocation(line: 7, column: 18, scope: !10, inlinedAt: !37)
!43 = !DILocation(line: 8, column: 7, scope: !10, inlinedAt: !37)
!44 = !DILocation(line: 8, column: 18, scope: !10, inlinedAt: !37)
!45 = !DILocation(line: 8, column: 15, scope: !10, inlinedAt: !37)
!46 = !DILocation(line: 9, column: 9, scope: !10, inlinedAt: !37)
!47 = !DILocation(line: 10, column: 16, scope: !10, inlinedAt: !37)
!48 = !DILocation(line: 10, column: 14, scope: !10, inlinedAt: !37)
!49 = !DILocation(line: 10, column: 32, scope: !10, inlinedAt: !37)
!50 = !DILocation(line: 10, column: 30, scope: !10, inlinedAt: !37)
!51 = !DILocation(line: 12, column: 18, scope: !35)
