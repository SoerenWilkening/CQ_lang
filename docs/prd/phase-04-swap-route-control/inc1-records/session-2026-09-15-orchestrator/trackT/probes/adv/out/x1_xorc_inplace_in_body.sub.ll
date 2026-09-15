; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/out/x1_xorc_inplace_in_body.sub.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x1_xorc_inplace_in_body.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !10 {
    #dbg_declare(ptr undef, !15, !DIExpression(), !22)
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !23
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !23
    #dbg_value(i32 %h, !17, !DIExpression(), !24)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !25
  call void @cqrt_ry_i32(i32 %h1, double 3.000000e-01), !dbg !25
    #dbg_value(i32 %h1, !18, !DIExpression(), !24)
    #dbg_value(i32 0, !19, !DIExpression(), !24)
    #dbg_value(i32 0, !20, !DIExpression(), !26)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
    #dbg_value(i32 0, !20, !DIExpression(), !26)
    #dbg_value(i32 0, !19, !DIExpression(), !24)
    #dbg_value(i32 %h1, !18, !DIExpression(), !24)
  br label %4, !dbg !27

1:                                                ; preds = %4
  %m = call i32 @cqrt_measure_i32(i32 %h), !dbg !28
  %2 = add nsw i32 %m, %7, !dbg !29
  %m2 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !30
  %3 = add nsw i32 %2, %m2, !dbg !31
  ret i32 %3, !dbg !32

4:                                                ; preds = %4, %0
  %5 = phi i32 [ 0, %0 ], [ %8, %4 ]
  %6 = phi i32 [ 0, %0 ], [ %7, %4 ]
    #dbg_value(i32 %5, !20, !DIExpression(), !26)
    #dbg_value(i32 %6, !19, !DIExpression(), !24)
    #dbg_value(i32 %h1, !18, !DIExpression(), !24)
  call void @cqrt_xorc_i32(i32 %h1, i32 3), !dbg !33
    #dbg_value(i32 %h1, !18, !DIExpression(), !24)
  %m3 = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !36
  %7 = add nsw i32 %m3, %6, !dbg !37
    #dbg_value(i32 %7, !19, !DIExpression(), !24)
  %8 = add nuw nsw i32 %5, 1, !dbg !38
    #dbg_value(i32 %8, !20, !DIExpression(), !26)
  %9 = icmp eq i32 %8, 3, !dbg !39
  br i1 %9, label %1, label %4, !dbg !27, !llvm.loop !40
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !44 {
    #dbg_declare(ptr undef, !15, !DIExpression(), !45)
  %h = call i32 @cqrt_alloc_i32(i32 5), !dbg !47
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01), !dbg !47
    #dbg_value(i32 %h, !17, !DIExpression(), !48)
  %h1 = call i32 @cqrt_alloc_i32(i32 7), !dbg !49
  call void @cqrt_ry_i32(i32 %h1, double 3.000000e-01), !dbg !49
    #dbg_value(i32 %h1, !18, !DIExpression(), !48)
    #dbg_value(i32 0, !19, !DIExpression(), !48)
    #dbg_value(i32 0, !20, !DIExpression(), !50)
  %h_op = call i32 @cq_template_and_i32_hl(i32 %h, i32 1)
    #dbg_value(i32 0, !20, !DIExpression(), !50)
    #dbg_value(i32 0, !19, !DIExpression(), !48)
    #dbg_value(i32 %h1, !18, !DIExpression(), !48)
  br label %1, !dbg !51

1:                                                ; preds = %1, %0
  %2 = phi i32 [ 0, %0 ], [ %5, %1 ]
  %3 = phi i32 [ 0, %0 ], [ %4, %1 ]
    #dbg_value(i32 %2, !20, !DIExpression(), !50)
    #dbg_value(i32 %3, !19, !DIExpression(), !48)
    #dbg_value(i32 %h1, !18, !DIExpression(), !48)
  call void @cqrt_xorc_i32(i32 %h1, i32 3), !dbg !52
    #dbg_value(i32 %h1, !18, !DIExpression(), !48)
  %m = call i32 @cqrt_measure_i32(i32 %h_op), !dbg !53
  %4 = add nsw i32 %m, %3, !dbg !54
    #dbg_value(i32 %4, !19, !DIExpression(), !48)
  %5 = add nuw nsw i32 %2, 1, !dbg !55
    #dbg_value(i32 %5, !20, !DIExpression(), !50)
  %6 = icmp eq i32 %5, 3, !dbg !56
  br i1 %6, label %7, label %1, !dbg !51, !llvm.loop !57

7:                                                ; preds = %1
  %m2 = call i32 @cqrt_measure_i32(i32 %h), !dbg !59
  %8 = add nsw i32 %m2, %4, !dbg !60
  %m3 = call i32 @cqrt_measure_i32(i32 %h1), !dbg !61
  %9 = add nsw i32 %8, %m3, !dbg !62
  ret i32 %9, !dbg !63
}

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare void @cqrt_xorc_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

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
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackT/probes/adv/x1_xorc_inplace_in_body.c", directory: "/Users/sorenwilkening/Desktop/CQ_T", checksumkind: CSK_MD5, checksum: "ca36384c89d5c09eedceebc0c3dc2509")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "slice", scope: !8, file: !8, line: 9, type: !11, scopeLine: 9, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !17, !18, !19, !20}
!15 = !DILocalVariable(name: "v", scope: !10, file: !8, line: 10, type: !16)
!16 = !DIDerivedType(tag: DW_TAG_volatile_type, baseType: !13)
!17 = !DILocalVariable(name: "y", scope: !10, file: !8, line: 11, type: !13)
!18 = !DILocalVariable(name: "z", scope: !10, file: !8, line: 12, type: !13)
!19 = !DILocalVariable(name: "s", scope: !10, file: !8, line: 13, type: !13)
!20 = !DILocalVariable(name: "k", scope: !21, file: !8, line: 14, type: !13)
!21 = distinct !DILexicalBlock(scope: !10, file: !8, line: 14, column: 5)
!22 = !DILocation(line: 10, column: 18, scope: !10)
!23 = !DILocation(line: 11, column: 13, scope: !10)
!24 = !DILocation(line: 0, scope: !10)
!25 = !DILocation(line: 12, column: 13, scope: !10)
!26 = !DILocation(line: 0, scope: !21)
!27 = !DILocation(line: 14, column: 5, scope: !21)
!28 = !DILocation(line: 18, column: 16, scope: !10)
!29 = !DILocation(line: 18, column: 14, scope: !10)
!30 = !DILocation(line: 18, column: 32, scope: !10)
!31 = !DILocation(line: 18, column: 30, scope: !10)
!32 = !DILocation(line: 18, column: 5, scope: !10)
!33 = !DILocation(line: 15, column: 11, scope: !34)
!34 = distinct !DILexicalBlock(scope: !35, file: !8, line: 14, column: 33)
!35 = distinct !DILexicalBlock(scope: !21, file: !8, line: 14, column: 5)
!36 = !DILocation(line: 16, column: 14, scope: !34)
!37 = !DILocation(line: 16, column: 11, scope: !34)
!38 = !DILocation(line: 14, column: 28, scope: !35)
!39 = !DILocation(line: 14, column: 23, scope: !35)
!40 = distinct !{!40, !27, !41, !42, !43}
!41 = !DILocation(line: 17, column: 5, scope: !21)
!42 = !{!"llvm.loop.mustprogress"}
!43 = !{!"llvm.loop.unroll.disable"}
!44 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 20, type: !11, scopeLine: 20, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!45 = !DILocation(line: 10, column: 18, scope: !10, inlinedAt: !46)
!46 = distinct !DILocation(line: 20, column: 25, scope: !44)
!47 = !DILocation(line: 11, column: 13, scope: !10, inlinedAt: !46)
!48 = !DILocation(line: 0, scope: !10, inlinedAt: !46)
!49 = !DILocation(line: 12, column: 13, scope: !10, inlinedAt: !46)
!50 = !DILocation(line: 0, scope: !21, inlinedAt: !46)
!51 = !DILocation(line: 14, column: 5, scope: !21, inlinedAt: !46)
!52 = !DILocation(line: 15, column: 11, scope: !34, inlinedAt: !46)
!53 = !DILocation(line: 16, column: 14, scope: !34, inlinedAt: !46)
!54 = !DILocation(line: 16, column: 11, scope: !34, inlinedAt: !46)
!55 = !DILocation(line: 14, column: 28, scope: !35, inlinedAt: !46)
!56 = !DILocation(line: 14, column: 23, scope: !35, inlinedAt: !46)
!57 = distinct !{!57, !51, !58, !42, !43}
!58 = !DILocation(line: 17, column: 5, scope: !21, inlinedAt: !46)
!59 = !DILocation(line: 18, column: 16, scope: !10, inlinedAt: !46)
!60 = !DILocation(line: 18, column: 14, scope: !10, inlinedAt: !46)
!61 = !DILocation(line: 18, column: 32, scope: !10, inlinedAt: !46)
!62 = !DILocation(line: 18, column: 30, scope: !10, inlinedAt: !46)
!63 = !DILocation(line: 20, column: 18, scope: !44)
